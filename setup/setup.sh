#!/bin/bash


CLIENTKEYS="joe ian iggy-new fabian-2"
USERLIST="josephramsay xycarto"

KEYPATH=../tf
mkdir -p $KEYPATH

# Generate wireguard keys for each devserver
genclient () {
    for k in $CLIENTKEYS; do
        wg genkey | tee $KEYPATH/vp-devserver-$k-privatekey | wg pubkey > $KEYPATH/vp-devserver-$k-publickey
    done
}

# Generate a server wireguard key
genserver () {
    wg genkey | tee $KEYPATH/vp-vpngw-privatekey | wg pubkey > $KEYPATH/vp-vpngw-publickey
}

# Get GitHub ssh keys... somehow use them as wg keys? 
getghpubkeys () {
    for user in $USERLIST;
    do
        IFS=$','
        COUNTER=1
        PUBKEYS=$(curl https://api.github.com/users/$user/keys | jq '.[].key' | paste -sd, -)
        for key in $PUBKEYS;
        do
            echo $key > $KEYPATH/vp-gh-$user-$COUNTER-publickey
            COUNTER=$((COUNTER+1))
        done
        unset IFS
    done
    unset IFS

}
FN=vpn-pub.json
LOCAL_PATH=/tmp/keys
REMOTE_PATH=s3://vibrant-dragon/config

sync_keys () {
    aws s3 sync $LOCAL_PATH $REMOTE_PATH
}

test_setup () {
    k1=$(cat << EOF
[{"user":"username0","keys":[{"ip":"127.0.0.1","key":"ABCDEFGHIJKL"},{"ip":"192.168.0.1","key":"QWERTYUIOPAS"}]},
 {"user":"username1","keys":[{"ip":"127.0.0.2","key":"MNOPQRSTUVWX"}]}]
EOF
)
    k2=$(cat << EOF
[{"user":"username0","keys":[{"ip":"127.0.0.1","key":"ABCDEFGHIJKL"},{"ip":"192.168.0.1","key":"QWERTYUIOPAS"},{"ip":"172.16.1.100","key":"QAZWSXEDCRFV"}]},
 {"user":"username1","keys":[{"ip":"127.0.0.2","key":"MNOPQRSTUVWX"},{"ip":"172.16.1.100","key":"QAZWSXEDCRFV"}]},
 {"user":"username7","keys":[{"ip":"172.16.100.1","key":"MKONJIBHUVGY"}]}]
EOF
)

    echo $k1 | jq > $LOCAL_PATH/$FN

    USER1=username1
    IP1=172.16.1.100
    KEY1=QAZWSXEDCRFV

    USER2=username7
    IP2=172.16.100.1
    KEY2=MKONJIBHUVGY

    #cat $LOCAL_PATH/$FN

    write_key $USER1 $IP1 $KEY1
    #cat $LOCAL_PATH/$FN

    write_key $USER2 $IP2 $KEY2
    #cat $LOCAL_PATH/$FN

    diff <(echo "$k2" | jq ) <(echo "$(cat $LOCAL_PATH/$FN)")
}

write_key () {
    NEW_USER=$1
    NEW_IP=$2
    NEW_KEY=$3

    if [ ! -d $LOCAL_PATH ]; then
        mkdir -p $LOCAL_PATH/
        touch $LOCAL_PATH/$FN
    fi

    CHECK=$(cat $LOCAL_PATH/$FN | jq -r --arg U "$NEW_USER" '.[] | select(.user==$U) | .user')

    if [ -z "$CHECK" ]; then
        # If user name not found, add a new user
        echo "new-user $NEW_USER"
        JSTR=$(cat $LOCAL_PATH/$FN | jq -r --arg U "$NEW_USER" --arg NI "$NEW_IP" --arg NK "$NEW_KEY" '. += [{"user":$U,"keys":[{"ip":$NI,"key":$NK}]}]')
        echo $JSTR | jq > $LOCAL_PATH/$FN
    else
        # If username found, add the new key to the user
        echo "new-key $NEW_KEY"
        JSTR=$(cat $LOCAL_PATH/$FN | jq -r --arg U "$NEW_USER" --arg NI "$NEW_IP" --arg NK "$NEW_KEY" '. | select(.[].user==$U) | .[].keys += [{"ip":$NI,"key":$NK}]')
        echo $JSTR | jq > $LOCAL_PATH/$FN
    fi
}

# Write keys from config to terraform WG vars
insert_keys(){
    #Format ref
    # wg_client_public_keys = [ { "192.168.2.2/32" = "QFX/DXxUv56mleCJbfYyhN/KnLCrgp7Fq2fyVOk/FWU=" }, ... ]} 
    k=$(cat $LOCAL_PATH/$FN)
    outk="wg_client_public_keys = ["
    echo $k | jq '.[].keys[] | "{ #"+(.ip)+"# = #"+(.key)+"# }"' | tr -d '"' | tr '#' '"' | xargs $outk +


#ssm (){
#    echo aws ssm put-parameter \
#        --name /wireguard/wg-server-private-key \
#        --type SecureString \
#        --value $(cat $KEYPATH/vp-vpngw-privatekey)
#}

#genclient
#genserver
#getghpubkeys
#ssm
#sync_keys
test_setup
#sync_keys