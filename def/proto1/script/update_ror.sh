#!/bin/sh
# open the configuration file in the pacakges root
# in order to retreive all input varaibles
source ror.dat
# see ror.dat
#old_ruby_input="ruby-2.0.0-p247"
#new_ruby_input="ruby-2.0.0-p247"
#
#libyaml_srclink_input='http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz'
#libyaml_srctar_input='yaml-0.1.4.tar.gz'
#libyaml_srcdir_input='yaml-0.1.4'
#
#ruby_srclink_input='http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz'
#ruby_srctar_input='ruby-2.0.0-p247.tar.gz'
#ruby_srcdir_input='ruby-2.0.0-p247'

#set -v

# indentation for title
tab1="   * "
# indentation for content
tab2="     >> "

echo "***************************************************************************"
echo "* Do you want to update on /depot/packages ?  Yes/No    *"
echo "***************************************************************************"
echo -n ">"
read answer

if  [ "$answer" == "Yes" ]; then
  machine_name="depot"
  ruby_package_input="/depot/packages"
else
  machine_name="local"
  ruby_package_input="~/.ruby/packages"
fi
  echo "machine name is $machine_name"
  echo "ruby package directory is: $ruby_package_input"

echo -n "$tab1 Is the machine name correct? Yes/No"
echo -n ">"
read answer
if  [ "$answer" == "Yes" ]; then
# do nothing
  echo "Thanks for confirmation"
else
# exit
  echo "$tab2 The specified machine for Ruby upgrading is unknown.."
  echo "$tab2 Please choose a correct machine (either depot or local) for upgrading."
  exit 1
fi


# check the existing ruby
echo  "$tab1 Check gem environment BEFORE ruby installed >"
echo ""
echo ""
echo  `gem env | grep INSTALL`
read text


# preparation
echo  "$tab1 Backup the current Ruby package (Please backup manually when doing it on anthem ) *** > "
read text

cd $ruby_package_input
date_str=`date +"%F"`
old_ruby_tar="${old_ruby_input}-${date_str}.tar"
echo "tar cvf $old_ruby_tar $old_ruby_input"
tar cvf $old_ruby_tar $old_ruby_input
echo  "$tab1 check backup result > "
read text
if [ -f "$old_ruby_tar" ]; then
  echo "$tab2 $old_ruby_tar found"
else
  echo "$tab2 $old_ruby_tar not found"
  echo "backup failed"
  #exit 1
fi


#if [ $machine_name == "local" ]; then
  #rm -rf $old_ruby_input
#fi
#set +v

mkdir $new_ruby_input
new_ruby_dir=$ruby_package_input/$new_ruby_input
sed_logical_path="rubybuild/sed-4.2.1/bin"
sed_path="${ruby_package_input}/${sed_logical_path}"
echo  "$tab1 Add sed to the path "
echo `sed --version | grep version`
read text
PATH="$sed_path:$PATH"
echo $PATH
rehash
echo
echo `sed --version | grep version`

src="src"
echo "--------------------------------------------------------------"
echo  "$tab1 Make sure ruby libyaml are ready > "
echo -n ">"
read libyaml_answer
# check if the new source dir is available. If not, then download and create it
new_libyaml_src="${ruby_package_input}/${src}/${libyaml_srcdir_input}"
if [ -d "$new_libyaml_src" ]; then
  echo "$tab2 $new_libyaml_src found"
else
  echo "$tab2 $new_libyaml_src NOT found"

  cd $ruby_package_input
  cd $src
  wget $libyaml_srclink_input
  tar xvf $libyaml_srctar_input

  echo  "$tab1 Check again to see if libyaml exists >"
  read text
  if [ -d "$new_libyaml_src" ]; then
    echo "$tab2 $new_libyaml_src found"
  else
    echo "$tab2 $new_libyaml_src NOT found"
  fi
fi
cd $new_libyaml_src
echo "current directory is :"
echo `pwd`


echo  "$tab1 Compile libyaml > "
read text
libyaml='libyaml'
new_libyaml="${new_ruby_dir}/${libyaml}/"
echo  "./configure --prefix=$new_libyaml"
read text
./configure --prefix=$new_libyaml
#make > /dev/null
make install # > /dev/null



#set -x
echo "---------------------------------------------------"
echo "$tab1 Make sure ruby is ready > "
echo "---------------------------------------------------"
read text
# go to source directory
cd $ruby_package_input
cd $src
new_ruby_srcdir="${ruby_package_input}/${src}/${ruby_srcdir_input}"
# check if the new ruby source is available. If not, then download it
if [ -d "$new_ruby_srcdir" ]; then
  echo "$tab2 $new_ruby_srcdir found."
else
  echo "$tab2 $new_ruby_srcdir not found."
  pwd
  wget $ruby_srclink_input
  tar xvf $ruby_srctar_input

  echo  "---------------------------------------------------"
  echo  "$tab1 Check again for ruby source > "
  echo  "---------------------------------------------------"
  # check again to see if the ruby src is ready
  if [ -d "$new_ruby_srcdir" ]; then
    echo "$tab2 $new_ruby_srcdir found."
  else
    echo "$tab2 $new_ruby_srcdir not found."
  fi
fi
cd $ruby_srcdir_input

#set +x
read text

dir=`pwd`
echo  "---------------------------------------------------"
echo  "$tab1 Compile new ruby > $dir"
echo  "---------------------------------------------------"
read text
# install the new ruby
#echo  "./configure --prefix=$new_ruby_dir --enable-shared --disable-install-doc --with-opt-dir=$new_libyaml"
#if [ "$libyaml_answer" == "Yes" ]; then
  echo "./configure --prefix=$new_ruby_dir --enable-shared --disable-install-doc --with-opt-dir=$new_libyaml"
#else
#  str_cmd="./configure --prefix=$new_ruby_dir "
#fi
read text
./configure --prefix=$new_ruby_dir --enable-shared --disable-install-doc --with-opt-dir=$new_libyaml
#else
#./configure --prefix=$new_ruby_dir --enable-shared --disable-install-doc --with-opt-dir=$new_libyaml
#./configure --prefix=$new_ruby_dir
make
make install
PATH="${new_ruby_dir}/bin:$PATH"
rehash

echo  "---------------------------------------------------"
echo  "$tab1 Check gem environment after ruby installed >"
echo  "---------------------------------------------------"
echo  `gem env | grep INSTALL`
read text



read text
cd $new_ruby_dir
dir=`pwd`
echo  "---------------------------------------------------"
echo  "$tab1 Install bundler > $dir"
echo  "---------------------------------------------------"
gem install bundler
rehash

echo  "---------------------------------------------------"
echo  "$tab1 Check gem environment after bundler installed "
echo  "---------------------------------------------------"
echo `gem env | grep INSTALL`
read text

echo  "---------------------------------------------------"
echo  "$tab1 Check Gemfile"
echo  "---------------------------------------------------"
read text

#  Copy the Gemfile from current ruby directory to the new ruby directory
#  Update the Rails version in Gemfile
gemfile_path_input="${ruby_package_input}/${old_ruby_input}/Gemfile"
gemfile_path="${ruby_package_input}/Gemfile"
if [ -f "$gemfile_path" ]; then
  cd $new_ruby_dir
  cp $gemfile_path_input  Gemfile
else
  echo "$tab2 $gemfile_path_input not found"
  exit 1
fi

echo  "---------------------------------------------------"
echo  "$tab1 Review Gemfile"
echo  "---------------------------------------------------"
cat $gemfile_path_input
read text


echo  "---------------------------------------------------"
echo  "$tab1 Install Rails via Gemfile > "
echo  "---------------------------------------------------"
read text

bundle install
./bin/passenger-install-apache2-module
passenger_conf="httpd-passenger.conf"
ls -al ./lib/ruby
echo "********************************************************************************************"
echo ""
echo "  * Create the apache conf file for passenger gem "
echo "    - Please create $passenger_conf in the $new_ruby_dir directory"
echo ""
echo "  * Verify gems directory permission : drwxr-xr-x "
echo "    - The gems files should be write-protectable: "
echo "      If the gems directory's group permission is writable,"
echo "      then run the following command: $ chmod g-w -R ./lib/ruby/gems/"
echo ""
echo "  * Update the application's ruby softlink (i.e. def/packages/ruby) to the new ruby directory"
echo ""
echo "********************************************************************************************"


#set +x
