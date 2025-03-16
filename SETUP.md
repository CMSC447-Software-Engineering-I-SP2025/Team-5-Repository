# Setup
### MacOS
Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) from the [AppStore](https://apps.apple.com/us/app/xcode/id497799835?mt=12)

Install [Homebrew](https://brew.sh)

### Install PostgreSQL
First we'll install PostgreSQL
```bash
brew install postgresql
```

Next we'll start the service
```bash
brew services start postgresql
```

Next we need to create a database user for the app, use the password `movies`
```bash
createuser -P movies_user
```

Next we need to create the database itself for the app.
```bash
createdb -O movies_user movies_database
```

Now we're good to go to build the app.
#### Optional
Install Postico (Postgres GUI)
```bash
brew install postico
```





#
### Ubuntu/WSL
#### Install Swift
Install swiftly (Swift toolchain manager tool) using a script using the command:

```bash
curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
```

You may need to restart your shell and/or run
```bash
source ~/.profile
```

Install Swift (Versions may be higher)
```
$ swiftly install latest

Fetching the latest stable Swift release...
Installing Swift 5.8.1
Downloaded 488.5 MiB of 488.5 MiB
Extracting toolchain...
Swift 5.8.1 installed successfully!

$ swift --version

Swift version 5.8.1 (swift-5.8.1-RELEASE)
Target: x86_64-unknown-linux-gnu
```

#### Install PostgreSQL
Install PostgreSQL with apt
```bash
sudo apt update && sudo apt -y upgrade
sudo apt install postgresql
```

Start PostgreSQL
```bash
sudo service postgresql start
```

Login as postgres user to do the next 2 commands.  
First run the following to impersonate postgres user
```bash
sudo su - postgres
```

Next we need to create a database user for the app, use the password `movies`
```bash
createuser -P movies_user
```

Finally we need to create the database itself for the app.
```bash
createdb -O movies_user movies_database
```


#### Install VSCode
To install VSCode in WSL run through the instructions [here](https://code.visualstudio.com/docs/setup/linux#_install-vs-code-on-linux)

Setup is now complete