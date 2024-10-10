$userName = "intellic"
$Userexist = (Get-LocalUser).Name -Contains $userName
if ($userexist) { 
  Write-Host "$userName exists" 
  Exit 1
} 
Else {
  Write-Host "$userName does not exist"
  Exit 0
}