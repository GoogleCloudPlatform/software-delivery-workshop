

create () {
    cp -R $BASE_DIR/resources/repos/app-templates $WORK_DIR
    cd $WORK_DIR/app-templates
    $BASE_DIR/scripts/git/gh.sh create mcd-app-templates 
    git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
    git remote add origin $GIT_BASE_URL/mcd-app-templates
    git push origin main
    cd $BASE_DIR
    rm -rf $WORK_DIR/app-templates

    cp -R $BASE_DIR/resources/repos/shared-kustomize $WORK_DIR
    cd $WORK_DIR/shared-kustomize
    $BASE_DIR/scripts/git/gh.sh create mcd-shared_kustomize 
    git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
    git remote add origin $GIT_BASE_URL/mcd-shared_kustomize
    git push origin main
    cd $BASE_DIR
    rm -rf $WORK_DIR/shared-kustomize

}
delete () {
    $BASE_DIR/scripts/git/gh.sh delete mcd-app-templates 
    $BASE_DIR/scripts/git/gh.sh delete mcd-shared_kustomize 
}

# execute function matching first arg and pass rest of args through
$1 $2 $3 $4 $5 $6