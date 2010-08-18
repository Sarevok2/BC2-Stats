function include(jsFile) {
  document.write('<script type="text/javascript" src="' + jsFile + '"></scr' + 'ipt>'); 
}

include('md5_min.js');

function verifyRegistration(usr, pwd1, pwd2, md5pwd) {
  if (usr == '' || pwd1 == '' || pwd2 == '') {
    alert("Please fill out all fields");
    return false;
  }
  else if (usr.value.length < 3 || pwd1.value.length < 3 || pwd2.value.length < 3) {
    alert("Username and password must be at least 3 characters in length");
    return false;
  }
  else if (pwd1.value != pwd2.value) {
    alert("Passwords do not match");
    return false;
  }
  else {
    pwd2.value = "";
    md5hash(pwd1, md5pwd);
    return true;
  }
  return false;
}

function md5hash(pwd, md5pwd) {
  md5pwd.value = hex_md5(pwd.value);
  pwd.value = ""; 
}

function test() {
  alert("hey");
}

