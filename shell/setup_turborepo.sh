# make a brach on the main repo named the same as the monorepo
# add this as a subtree to the main repo
git subtree add --prefix=packages/scipts/dotfiles https://github.com/valiantlynx/dotfiles.git main --squash

# pull the subtree
git subtree pull --prefix=packages/scipts/dotfiles https://github.com/valiantlynx/dotfiles.git main --squash

# push the subtree
git subtree push --prefix=packages/scipts/dotfiles https://github.com/valiantlynx/dotfiles.git main
