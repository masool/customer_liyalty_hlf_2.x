cd customerloyalty/javascript/src/

  if [ -d "wallet" ]; then
  chmod 777 wallet
  rm -rf wallet
  echo "wallet folder deleted"
  else 
  echo "wallet folder not found"
  fi

sleep 2
echo
echo "installing node modules"
npm install
echo

sleep 2
echo "run enroll admin for customerloyalty ADMIN"
node enrollAdmin.js
echo
echo "start npm"
echo
# pm2 start app.js
npm start
