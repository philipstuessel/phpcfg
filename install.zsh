source ~/.zshrc
name="phpcfg"
folder="${JAP_FOLDER}plugins/packages/${name}/"
folder_config="${folder}config/"
fetch2 $folder "https://raw.githubusercontent.com/philipstuessel/$name/main/$name.zsh"
fetch2 $folder_config https://raw.githubusercontent.com/philipstuessel/$name/main/config/$name.config.json
echo "--phpcfg is installed--"