echo -e "# Scripts: Layout" > README.md
echo -e "\`\`\`" >> README.md
tree . >> README.md
echo -e "\`\`\`" >> README.md
cat >> README.md << EOF
# Introduction

A basic module containing platform dependent scripts.
EOF
