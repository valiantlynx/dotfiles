# If ~/.inputrc doesn't exist yet, include the original /etc/inputrc
if [ ! -a ~/.inputrc ]; then
  echo '$include /etc/inputrc' >> ~/.inputrc
fi

# Only add the "completion-ignore-case" line if it's not already present
grep -qxF 'set completion-ignore-case On' ~/.inputrc || echo 'set completion-ignore-case On' >> ~/.inputrc
