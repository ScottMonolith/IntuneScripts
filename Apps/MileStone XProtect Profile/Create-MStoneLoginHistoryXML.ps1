# Get the current username
$currentUsername = [Environment]::UserName

# Create an XML document
$xmlDoc = New-Object System.Xml.XmlDocument

# Load the XML structure
$xmlDoc.LoadXml(@"
<?xml version="1.0" encoding="utf-8"?>
<login>
  <lastlogin>
    <servertype>00000000-0000-0000-0000-000000000000</servertype>
    <serveraddress>http://10.180.100.244/</serveraddress>
    <authenticationtype>WindowsDefault</authenticationtype>
    <username />
    <rememberpassword>True</rememberpassword>
    <autologin>True</autologin>
    <showrememberpassword>True</showrememberpassword>
    <showautologin>True</showautologin>
  </lastlogin>
  <allowunsecureconnections>
    <user username="" allowunsecure="True" />
  </allowunsecureconnections>
  <historyaddress>
    <entry>http://10.180.100.244/</entry>
  </historyaddress>
  <historyusername />
</login>
"@)

# Update the username in the XML
$xmlDoc.login.allowunsecureconnections.user.SetAttribute("username", "corp\$currentUsername")

# Save the XML document to a file
$MStoneFolder = "$($env:appdata)\Milestone\Smart Client\"
if (!(Test-Path $MStoneFolder)) {
  $null = New-Item -Path "$MStoneFolder" -ItemType Directory
}
$xmlDoc.Save("$($MStoneFolder)\LoginHistory.xml")
