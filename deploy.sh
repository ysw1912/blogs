#########################################################################
# File Name: push.sh
# Author: Stewie
# E-mail: 793377164@qq.com
# Created Time: 2018-06-04
#########################################################################
#!/bin/bash

# Add changes to git 
git add .

if [ $# -lt  1 ]; then
    echo "$0 <commit message>"
    exit 1
fi

msg="$1"
git commit -m "$msg"
if [ $? -ne 0 ]; then
    echo "Commit failed"
    exit 1
fi
git push origin master
if [ $? -ne 0 ]; then
    echo "Push failed"
fi
                    
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
                    
# Build the project.
hugo -t jane
                    
# Go To Public folder
cd public
                    
# Add changes to git.
git add .
                    
# Commit changes.
git commit -m "$msg"
                    
# Push source and build repos.
git push origin master
                    
# Come Back up to the Project Root
cd ..
