fortigate_user "user001" do
  host 'fortigate'
  vdom 'root'

  passwd "randomPassHere"
  email "me@mydomain.com"
  type 'password'
end

fortigate_usergroup "testgroup001" do
  host 'fortigate'
  vdom 'root'

  member ['user001']
end
