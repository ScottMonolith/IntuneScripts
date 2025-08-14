# Create an XML document
$xmlDoc = New-Object System.Xml.XmlDocument

# Load the XML structure
$xmlDoc.LoadXml(@"
<?xml version="1.0" encoding="utf-8"?>
<LoginOptionsExtension xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <DatastoreHistory>
    <string>MONOOC1SEC02.corp.monolithmaterials.com</string>
  </DatastoreHistory>
  <UsernameHistory>
  </UsernameHistory>
  <IsSupervisorLogonRequired>false</IsSupervisorLogonRequired>
  <IsWindowsCredential>true</IsWindowsCredential>
  <RestrictConnectionParamsAccess>false</RestrictConnectionParamsAccess>
</LoginOptionsExtension>
"@)

# Save the XML document to a file
$GenetecFolder = "$($env:localappdata)\Genetec Security Center 5.12"
if (!(Test-Path $GenetecFolder)) {
  $null = New-Item -Path "$GenetecFolder" -ItemType Directory
}
$xmlDoc.Save("$($GenetecFolder)\LoginOptionsExtension.xml")