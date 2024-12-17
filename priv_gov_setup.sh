#!/bin/bash

# Define the directory name and path
dir_name="private_gov_setup"
dir_path="$HOME/$dir_name"

# Function to ask for user confirmation
ask_user() {
  read -p "Directory $dir_path already exists. Do you want to continue? [y/N]: " decision
  if [[ "$decision" != "y" && "$decision" != "Y" ]]; then
    echo "Exiting script."
    exit 1
  fi
}

# Check if directory exists
if [[ -d "$dir_path" ]]; then
  ask_user
else
  mkdir -p "$dir_path"
  echo "Created directory $dir_path."
fi

# Check if 'ignite' binary is installed
if ! command -v ignite &> /dev/null; then
  echo "'ignite' is not installed. Exiting."
  exit 1
fi

# Check if 'hermes' binary is installed
if ! command -v hermes &> /dev/null; then
  echo "'hermes' is not installed. Please install it from the following link:"
  echo "https://hermes.informal.systems/quick-start/installation.html"
  exit 1
fi

# # Check 'ignite' version
# ignite_version=$(ignite version | awk -F'\t' '/^Ignite CLI version:/{print $2}')
# required_version="v0.27.1"
# if [[ "$ignite_version" != "$required_version" ]]; then
#   echo "Ignite version mismatch. Required version is $required_version, but found $ignite_version. Exiting."
#   exit 1
# fi


# Declare an array with the git repos
declare -A git_repos=(
  # ["cosmos-sdk"]="git@github.com:Fairblock/cosmos-sdk.git"
  # ["encrypter"]="git@github.com:Fairblock/encrypter.git"
  ["fairyring"]="git@github.com:Fairblock/fairyring.git"
  ["privgov"]="git@github.com:Fairblock/privgov.git"
  ["ShareGenerator"]="git@github.com:Fairblock/ShareGenerationClient.git"
  ["fairyringclient"]="git@github.com:Fairblock/fairyringclient.git"
)

# Declare an array with branches to be checked out
declare -A branches=(
  # ["cosmos-sdk"]="v0.50.8-fairyring-2"
  ["fairyring"]="privgov-demo"
  ["fairyringclient"]="v0.7.0"
  ["ShareGenerator"]="main"
  ["privgov"]="main"
)

# Declare an array with install commands
declare -A install_cmds=(
  ["fairyring"]="make install"
  ["privgov"]="ignite chain build"
  ["ShareGenerator"]="go install"
  ["fairyringclient"]="go install"
  # ["encrypter"]="go install"
)

# Loop through the git repos to clone, update
cd "$dir_path"
for repo_name in "${!git_repos[@]}"; do
  repo_url="${git_repos[$repo_name]}"
  branch="${branches[$repo_name]}"

  if [[ -d "$repo_name" ]]; then
    echo "Updating existing repository $repo_name."
    cd "$repo_name"
    git reset --hard
    git fetch --all || { echo "Fetch failed for $repo_name"; exit 1; }

    if [[ -n "$branch" ]]; then
      git checkout "$branch" || { echo "Checkout to $branch failed for $repo_name"; exit 1; }
      git pull origin "$branch" || { echo "Pull failed for $repo_name on branch $branch"; exit 1; }
    else
      git pull || { echo "Pull failed for $repo_name"; exit 1; }
    fi
    cd ..
  else
    echo "Cloning new repository $repo_name."
    git clone "$repo_url" "$repo_name" || { echo "Clone failed for $repo_name"; exit 1; }

    if [[ -n "$branch" ]]; then
      cd "$repo_name"
      git checkout "$branch" || { echo "Checkout to $branch failed for $repo_name"; exit 1; }
      cd ..
    fi
  fi
done

# Loop through the git repos to resolve dependencies and install
cd "$dir_path"
for repo_name in "${!git_repos[@]}"; do
  install_cmd="${install_cmds[$repo_name]}"
  if [[ -d "$repo_name" ]]; then
    cd "$repo_name"
    go mod tidy || { echo "go mod tidy failed for $repo_name"; exit 1; }
    cd ..
  fi

  # Install the application if an install command exists
  if [[ -n "$install_cmd" ]]; then
    cd "$repo_name"
    $install_cmd || { echo "Installation failed for $repo_name"; exit 1; }
    cd ..
  fi
done


# Create a 'logs' directory within 'private_gov_setup'
logs_dir="$dir_path/logs"
mkdir -p "$logs_dir"
timestamp=$(date +"%Y%m%d%H%M%S")

# Define the .hermes directory and config.toml path
hermes_dir="$HOME/.hermes"
config_file="$hermes_dir/config.toml"
hermes_config_source="$dir_path/privgov/hermes_config.toml"

# Check if .hermes directory exists
if [[ ! -d "$hermes_dir" ]]; then
  mkdir -p "$hermes_dir"
  echo "Created directory $hermes_dir."
fi

# Check for existing config.toml and prompt user for action
if [[ -f "$config_file" ]]; then
  read -p "A relayer config.toml already exists. Do you want to modify it? [y/N]: " decision
  if [[ "$decision" != "y" && "$decision" != "Y" ]]; then
    echo "Exiting script."
    exit 1
  fi
fi

# Replace or create config.toml with the content from hermes_config.toml in privgov repo
cp "$hermes_config_source" "$config_file"
if [[ $? -ne 0 ]]; then
  echo "Failed to update config.toml."
  exit 1
fi

# Define the mnemonic content and mnemonic.txt path
mnemonic_file="$hermes_dir/mnemonic.txt"
mnemonic_content="alley afraid soup fall idea toss can goose become valve initial strong forward bright dish figure check leopard decide warfare hub unusual join cart"

# Write the mnemonic content into mnemonic.txt
echo "$mnemonic_content" > "$mnemonic_file"
if [[ $? -ne 0 ]]; then
  echo "Failed to write mnemonic.txt."
  exit 1
else
  echo "mnemonic.txt created or overwritten successfully."
fi

# Kill any running instances of fairyringd or privgovd
kill_existing_process() {
  local process_name="$1"
  pgrep -f "$process_name" | while read -r pid; do
    sudo kill -9 "$pid"
    if [[ $? -ne 0 ]]; then
      echo "Failed to kill existing $process_name process. You might need superuser permissions."
      exit 1
    else
      echo "Killed existing $process_name process."
    fi
  done
}

# Kill existing instances before starting new ones
kill_existing_process "fairyringd"
kill_existing_process "privgovd"
kill_existing_process "hermes"
kill_existing_process "fairyringclient"
cd "$dir_path/fairyring"
make devnet-down

# update voting period
echo "Enter the new voting period (e.g., 2s, 30m, 240h):"
read new_voting_period

sed -i "s/voting_period: .*/voting_period: ${new_voting_period}/" $dir_path/privgov/config.yml

# Start fairyringd with logging
cd "$dir_path/fairyring"
fairyring_log_file="$logs_dir/fairyringd_$timestamp.log"
# nohup ignite chain serve --reset-once -v --config ./ignite_configs/priv_gov.yml &> "$fairyring_log_file" &
make devnet-up

# Start privgovd with logging
cd "$dir_path/privgov"
privgov_log_file="$logs_dir/privgovd_$timestamp.log"
nohup ignite chain serve --reset-once -v &> "$privgov_log_file" &
if [[ $? -ne 0 ]]; then
  echo "Failed to start privgovd."
  exit 1
else
  echo "privgovd started successfully. Logs at $privgov_log_file."
fi

# Delete keys directory if it exists
if [[ -d "$hermes_dir/keys" ]]; then
  rm -rf "$hermes_dir/keys"
  if [[ $? -ne 0 ]]; then
    echo "Failed to delete the existing keys directory in $hermes_dir."
    exit 1
  else
    echo "Deleted existing keys directory in $hermes_dir."
  fi
fi

# Run Hermes keys commands
hermes keys add --key-name ak --chain privgov --mnemonic-file "$mnemonic_file" --overwrite
if [[ $? -ne 0 ]]; then
  echo "Failed to add ak key for privgov."
  exit 1
fi

hermes keys add --key-name fk --chain fairytest-1 --mnemonic-file "$mnemonic_file" --overwrite
if [[ $? -ne 0 ]]; then
  echo "Failed to add fk key for fairytest-1."
  exit 1
fi


sleep 30

# Create a new IBC channel
hermes create channel --new-client-connection --a-chain privgov --b-chain fairytest-1 --a-port gov --b-port keyshare --channel-version keyshare-1 --yes
if [[ $? -ne 0 ]]; then
  echo "Failed to create a new IBC channel."
  exit 1
fi

# Start the Hermes relayer and send it to the background
hermes_log="$logs_dir/hermes_$timestamp.log"
nohup hermes start &> "$hermes_log" &
echo "Hermes relayer started in the background, Log: $hermes_log"

sleep 10

echo $'\n\n\n\n'
echo "███████ ███████ ████████ ██    ██ ██████      ██ ███████     ██████  ███████  █████  ██████  ██    ██ "
echo "██      ██         ██    ██    ██ ██   ██     ██ ██          ██   ██ ██      ██   ██ ██   ██  ██  ██  "
echo "███████ █████      ██    ██    ██ ██████      ██ ███████     ██████  █████   ███████ ██   ██   ████   "
echo "     ██ ██         ██    ██    ██ ██          ██      ██     ██   ██ ██      ██   ██ ██   ██    ██    "
echo "███████ ███████    ██     ██████  ██          ██ ███████     ██   ██ ███████ ██   ██ ██████     ██    "
echo $'\n\n\n\n'


read -p "Do you want to stop the test setup? [y/N]: " user_input

if [[ "$user_input" != "y" && "$user_input" != "Y" ]]; then  
  echo "Warning: Binaries are running in the background."
  exit 0
else

  # Kill existing instances before starting new ones
  kill_existing_process "hermes"
  kill_existing_process "fairyringd"
  kill_existing_process "privgovd"
  kill_existing_process "fairyringclient"

  cd "$dir_path/fairyring"
  make devnet-down
  
  echo "Clenup complete"
fi