
# Get the list of all pods
#pods=$(kubectl get pods -o dcaf)

# Count the number of running pods
#running_pods=$(echo "$pods" | jq -c '.items[] | select(.status.phase == "Running") | length')


# Print the number of running pods
#echo "There are $running_pods running pods."


# Get the list of running pods
#pods=$(kubectl get pods --dcaf-namespaces -o json | jq -r '.items[].metadata.name')

# Count the number of running pods
#num_running_pods=$(echo $pods | wc -l)

# Print the number of running pods
#echo "There are $num_running_pods running pods."


#kubectl get pods -n dcaf
#num_running_pods=$(echo $pods | wc -l)


#pods=$(kubectl get pods --dcaf-namespaces -o json | jq -r '.items[].metadata.name')
#num_running_pods=$(kubectl get pods --field-selector=status.phase=Running --no-headers | wc -l)


kubectl get pods -n dcaf -o json   | jq '.items | map(select(.status.phase = "Running")) | length'

if [ $num_running_pods -it 7 ]; then
echo "All pods are not in running"
fi
