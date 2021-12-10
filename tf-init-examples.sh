#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e


# This script can be used to easily run terraform init against all the exampels
# Can be useful to verify that all the examples init properly (e.g. providers versions errors)

EXCLUDE_DIRS=(
    "! -path *.terraform*"
    "! -path */gitlab-ci-cd/*"
)

# Find all main.tf files in the current directory and all subdirectories.
main_tf_locations=$(find . -name 'main.tf' ${EXCLUDE_DIRS[@]} -exec dirname {} \; | sort -u)

#Print the list of main.tf files
echo "main.tf files found:"
echo "$main_tf_locations"

# Terraform init for every main.tf folder location.
for location in $main_tf_locations; do
    echo "###### Verifying TF Init for $location ##########"
    terraform -chdir=$location init
    echo "##################################################"
done
