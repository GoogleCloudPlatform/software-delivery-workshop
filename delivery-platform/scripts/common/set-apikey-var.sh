source ${BASE_DIR}/scripts/common/manage-state.sh

if [[ ${API_KEY_VALUE} == "" ]]; then
    echo ""
    echo "No API Key found. Please generate a key from the URL and paste it at the prompt."
    echo "Goto https://console.cloud.google.com/apis/credentials > 'Create Credentials' > 'API Key'"
    echo "As a best practice, you can restrict the key to Cloud Build API under 'API restrictions' > 'Restrict key'"
    echo ""
    printf "Paste your API Key here and press enter: " && read keyval
    export API_KEY_VALUE=${keyval}
    echo ""
fi

write_state