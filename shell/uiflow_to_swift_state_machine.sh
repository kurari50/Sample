
set -e -u

# ■ルール
# [画面名_状態名]とすること
#   画面名に"画面"とつけること
#     "画面"は SCREEN_STRING で変更可能
#   状態名に"状態"とつけること
#     "状態"は STATE_STRING で変更可能
#   状態名は必須
#     "_"は SCREEN_AND_STATE_SPLITTER で変更可能だが、正規表現のパターンにないものにすること
# ViewModelは手動で作成する
# イベントで値を使用する場合は"イベント（値1: 型, 値2: 型）"と記載するとViewModelのメソッドを呼び出す
#   ViewModel側のメソッドは"func イベント(_ 値1: 型,_ 値2: 型)"とする
# イベントで条件判定が必要な場合は"イベント（値1: 型, 値2: 型）が○○な場合"と記載するとViewModelのメソッドを呼び出す
#   ViewModel側のメソッドは"func is○○イベント(_ 値1: 型,_ 値2: 型) -> Bool"とする
# 同一画面内での状態変更ではない場合はRouterのメソッドを呼び出す
#   Router側のメソッドは"class func request(_ screen: ScreenEnum)"とする
#     "Router.request"は ROUTER_REAUEST_METHOD で変更可能
#     "ScreenEnum"は SCREEN_ENUM_NAME で変更可能

if [ $# -eq 1 ]
then
    INPUT_FILE=$1
    OUTPUT_DIR=""
elif [ $# -eq 2 ]
then
    INPUT_FILE=$1
    OUTPUT_DIR=$2
else
    echo Usage: $0 [input_file]
    echo Usage: $0 [input_file] [output_dir]
    exit 1
fi

SCREEN_AND_STATE_SPLITTER="_"
SCREEN_ENUM_NAME="ScreenEnum"
STATE_ENUM_NAME="StateEnum"
EVENT_ENUM_NAME="EventEnum"
STATE_MACHINE_SUFFIX="StateMachine"
SCREEN_STRING="画面"
STATE_STRING="状態"
STATE_MACHINE_DEFAULD_STATE="通常状態"
STATE_MACHINE_EVENT_HANDLER_NAME="handleEvent"
EVENT_CONDITION_DELETE_PATTERN="が.*な場合"
EVENT_CONDITION_EXTRACT_PATTERN=".*が\(.*\)な場合"
EVENT_EXTRACT_PATTERN="\(.*\)が.*な場合"
ROUTER_REAUEST_METHOD="Router.request"
VIEWMODEL_HANDLE_INPUT_METHOD="viewModel."

echo INPUT_FILE: $INPUT_FILE
echo OUTPUT_DIR: $OUTPUT_DIR

SCREEN_STATE_LIST=$(grep "\[" $INPUT_FILE | grep "\]" | sed "s/\[//" | sed "s/\]//")

SCREEN_LIST=()

echo
echo SCREEN_STATE_LIST:
for v in $SCREEN_STATE_LIST
do
    echo $v

    set +e
    echo $v | grep $SCREEN_AND_STATE_SPLITTER > /dev/null
    HAS_STATE=$?
    set -e
    if [ $HAS_STATE -eq 0 ]
    then
        SCREEN_NAME=$(echo $v | grep $SCREEN_AND_STATE_SPLITTER | sed "s/\(.*\)$SCREEN_AND_STATE_SPLITTER.*/\1/")
    else
        SCREEN_NAME=$v
    fi
    SCREEN_NAME=$(echo $SCREEN_NAME | sed "s/$SCREEN_STRING//")

    if [ ${#SCREEN_LIST[*]} -eq 0 ]
    then
        EXIST=0
    else
        EXIST=0
        for v in ${SCREEN_LIST[@]}
        do
            if [ $v = $SCREEN_NAME ]
            then
                EXIST=1
            fi
        done
    fi

    if [ $EXIST -eq 0 ]
    then
        SCREEN_LIST+=($SCREEN_NAME)
    fi
done

SCREEN_ENUM_SWIFT_FILE_NAME=${SCREEN_ENUM_NAME}".swift"
STATE_ENUM_SWIFT_FILE_NAME=${STATE_ENUM_NAME}".swift"
EVENT_ENUM_SWIFT_FILE_NAME=${EVENT_ENUM_NAME}".swift"

echo
OUTPUT_SCREEN_ENUM_SWIFT_FILE=${OUTPUT_DIR}/${SCREEN_ENUM_SWIFT_FILE_NAME}
echo OUTPUT_SCREEN_ENUM_SWIFT_FILE: $OUTPUT_SCREEN_ENUM_SWIFT_FILE
if [ -e $OUTPUT_SCREEN_ENUM_SWIFT_FILE ]
then
    rm $OUTPUT_SCREEN_ENUM_SWIFT_FILE
fi

OUTPUT_STATE_ENUM_SWIFT_FILE=${OUTPUT_DIR}/${STATE_ENUM_SWIFT_FILE_NAME}
echo OUTPUT_STATE_ENUM_SWIFT_FILE: $OUTPUT_STATE_ENUM_SWIFT_FILE
if [ -e $OUTPUT_STATE_ENUM_SWIFT_FILE ]
then
    rm $OUTPUT_STATE_ENUM_SWIFT_FILE
fi

OUTPUT_EVENT_ENUM_SWIFT_FILE=${OUTPUT_DIR}/${EVENT_ENUM_SWIFT_FILE_NAME}
echo OUTPUT_EVENT_ENUM_SWIFT_FILE: $OUTPUT_EVENT_ENUM_SWIFT_FILE
if [ -e $OUTPUT_EVENT_ENUM_SWIFT_FILE ]
then
    rm $OUTPUT_EVENT_ENUM_SWIFT_FILE
fi

echo "enum $SCREEN_ENUM_NAME {" >> $OUTPUT_SCREEN_ENUM_SWIFT_FILE

echo
for SCREEN_NAME in ${SCREEN_LIST[@]}
do
    echo "SCREEN: "${SCREEN_NAME}${SCREEN_STRING}

    echo "    case "$SCREEN_NAME >> $OUTPUT_SCREEN_ENUM_SWIFT_FILE

    echo "extension "${SCREEN_NAME}${STATE_MACHINE_SUFFIX}" {" >> $OUTPUT_STATE_ENUM_SWIFT_FILE

    echo "protocol ${SCREEN_NAME}StateChangeHandling {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    func onEntryState(_ state: ${SCREEN_NAME}${STATE_MACHINE_SUFFIX}.State, viewModel: ${SCREEN_NAME}ViewModel)" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    func onExitState(_ state: ${SCREEN_NAME}${STATE_MACHINE_SUFFIX}.State, viewModel: ${SCREEN_NAME}ViewModel)" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "}" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE

    echo "class "${SCREEN_NAME}${STATE_MACHINE_SUFFIX}" {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    var state: State = ."$STATE_MACHINE_DEFAULD_STATE | sed "s/$STATE_STRING//" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    private let viewModel: "${SCREEN_NAME}"ViewModel" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    private let handler: ${SCREEN_NAME}StateChangeHandling?" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE

    echo "    init(viewModel: "${SCREEN_NAME}"ViewModel, handler: ${SCREEN_NAME}StateChangeHandling? = nil) {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "        self.viewModel = viewModel" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "        self.handler = handler" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
    echo "    }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE

    EVENT_LIST=()

    STATE_LIST=$(grep "\[" $INPUT_FILE | grep "${SCREEN_NAME}${SCREEN_STRING}_" | grep "\]" | sed "s/\[.*$SCREEN_AND_STATE_SPLITTER//" | sed "s/\]//" | sed "s/$STATE_STRING//")
    if [ "$STATE_LIST" == "" ]
    then
        echo "    STATE: 未定義"
    else
        echo "    enum State {" >> $OUTPUT_STATE_ENUM_SWIFT_FILE
        echo "    func $STATE_MACHINE_EVENT_HANDLER_NAME(_ event: Event) {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        var newState = state" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        switch (state, event) {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE

        for STATE in $STATE_LIST
        do
            echo "    STATE: "${STATE}${STATE_STRING}

            echo "        case "$STATE >> $OUTPUT_STATE_ENUM_SWIFT_FILE

            echo "        EVENT HANDLING: "

            EVENT_HANDLER_LIST=$(awk 'BEGIN { active=0; preline=""; prepreline="" } { prepreline=preline; preline=$0 } /==/ { if (active) {print "            " prepreline " " $0 } } /^\[/ { active=0 } /^\['${SCREEN_NAME}${SCREEN_STRING}'_'${STATE}${STATE_STRING}'\]/ { active=1 }' $INPUT_FILE | sed "s/${SCREEN_NAME}${SCREEN_STRING}$SCREEN_AND_STATE_SPLITTER//" | sed "s/ //g")
            for EVENT_HANDLER in $EVENT_HANDLER_LIST
            do
                NEW_STATE=$(echo $EVENT_HANDLER | sed "s/.*==//" | sed "s/>//" | sed "s/$STATE_STRING//")
                if [ $STATE != $NEW_STATE ]
                then
                    echo "            "$EVENT_HANDLER

                    EVENT=$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_CONDITION_DELETE_PATTERN//" | sed "s/（/(/" | sed "s/）/)/")
                    set +e
                    echo $EVENT | grep "(.*)" > /dev/null
                    HAS_EVENT_PARAM=$?
                    set -e
                    if [ $HAS_EVENT_PARAM -eq 0 ]
                    then
                        echo "        case (."$STATE", let ."$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_CONDITION_DELETE_PATTERN//" | sed "s/（/(/" | sed "s/）/)/" | sed "s/:String//g")"): " >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                    else
                        echo "        case (."$STATE", ."$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_CONDITION_DELETE_PATTERN//" | sed "s/（/(/" | sed "s/）/)/")"): " >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                    fi

                    set +e
                    echo $EVENT_HANDLER | grep -E "$EVENT_CONDITION_DELETE_PATTERN" > /dev/null
                    HAS_CONDITION=$?
                    set -e
                    if [ $HAS_CONDITION -eq 0 ]
                    then
                        CONDITION=$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_CONDITION_EXTRACT_PATTERN/\1/")
                        INPUT=$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_EXTRACT_PATTERN/\1/" | sed "s/（/(/" | sed "s/）/)/" | sed "s/:String//g")
                        echo "            "${VIEWMODEL_HANDLE_INPUT_METHOD}${INPUT} >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        echo "            if viewModel.is"$CONDITION$INPUT" {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        set +e
                        echo $NEW_STATE | grep $SCREEN_AND_STATE_SPLITTER > /dev/null
                        HAS_SCREEN=$?
                        set -e
                        if [ $HAS_SCREEN -eq 0 ]
                        then
                            NEW_SCREEN=$(echo $NEW_STATE | grep $SCREEN_AND_STATE_SPLITTER | sed "s/\(.*\)$SCREEN_AND_STATE_SPLITTER.*/\1/" | sed "s/$SCREEN_STRING//")
                            echo "                $ROUTER_REAUEST_METHOD(."$NEW_SCREEN")" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        else
                            echo "                newState = ."$NEW_STATE >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        fi
                        echo "            }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                    else
                        set +e
                        echo $NEW_STATE | grep $SCREEN_AND_STATE_SPLITTER > /dev/null
                        HAS_SCREEN=$?
                        set -e
                        if [ $HAS_SCREEN -eq 0 ]
                        then
                            NEW_SCREEN=$(echo $NEW_STATE | grep $SCREEN_AND_STATE_SPLITTER | sed "s/\(.*\)$SCREEN_AND_STATE_SPLITTER.*/\1/" | sed "s/$SCREEN_STRING//")
                            echo "            $ROUTER_REAUEST_METHOD(."$NEW_SCREEN")" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        else
                            echo "            newState = ."$NEW_STATE >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
                        fi
                    fi
                fi

                EVENT=$(echo $EVENT_HANDLER | sed "s/==.*//" | sed "s/$EVENT_CONDITION_DELETE_PATTERN//" | sed "s/（/(/" | sed "s/）/)/")
                if [ ${#EVENT_LIST[*]} -eq 0 ]
                then
                    EXIST=0
                else
                    EXIST=0
                    for v in ${EVENT_LIST[@]}
                    do
                        if [ $v = $EVENT ]
                        then
                            EXIST=1
                        fi
                    done
                fi

                if [ $EXIST -eq 0 ]
                then
                    EVENT_LIST+=($EVENT)
                fi
            done
        done

        echo "    }" >> $OUTPUT_STATE_ENUM_SWIFT_FILE
        echo "        default: break" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        if let handler = handler, state != newState {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "            handler.onExitState(state, viewModel: viewModel)" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "            handler.onEntryState(newState, viewModel: viewModel)" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "        state = newState" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        echo "    }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE

        if [ ${#EVENT_LIST[*]} -ne 0 ]
        then
            echo "    enum Event {" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
            for EVENT in ${EVENT_LIST[@]}
            do
                echo "        case "$EVENT >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
            done
            echo "    }" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
        else
            echo "            なし"
        fi
    fi

    echo "}" >> $OUTPUT_STATE_ENUM_SWIFT_FILE
    echo "}" >> $OUTPUT_EVENT_ENUM_SWIFT_FILE
done

echo "}" >> $OUTPUT_SCREEN_ENUM_SWIFT_FILE

echo
echo FINISH
