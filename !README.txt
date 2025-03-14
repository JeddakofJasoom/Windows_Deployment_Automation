For the automated deployment to work on a USB do the following 3 steps:

1) format the USB drive as a windows 11 installer using either Rufus or Windows media creation tool. 
	It does not matter the settings, as the answer file will bypass the hardware requirements for you. 
2) copy the entire "SCRIPTS" folder into the root of your main partition for your USB (the larger partition that has the "sources" folder in it).
3) Copy the "autounattend.xml" file without changing the name into the ROOT of your USB drive. 
	The autounattend.xml must remain the same name, and it has to be in the root of your usb drive to function. This is a Microsoft requirement. 

Then, just boot to the USB through the UEFI, and walk away. The end step will prompt you to change the default local admin password when it is completed. The computer will reboot several times, and the powershell window will be visible at all times while running. 

AS of 03/12/2025 the required installers to be included in your "Scripts" folder on your USB installer must include:

- The following powershell scripts to automate installation. THEY MUST BE renamed to: 
	- new_setup_part_0.ps1
	- new_setup_part_1.ps1
	- new_setup_part_2.ps1
	- new_setup_part_3.ps1
	- new_setup_part_4.ps1
- OfficeSetup.EXE 
- O365Configuration.XML
- DefaultApps.XML


The standard batch file to run the installer script (as an admin) is:

	powershell.exe -command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit', '-ExecutionPolicy unrestricted', '-file \"%~dp0new_setup_part_0.ps1"'" 

*** IMPORTANT NOTE ***: each part of the script is set to run the next part on the next logon. HOWEVER, the autologons are configured through the autounattend.XML file. If you run this outside of the answer file, you'll have to manually login to the local admin account for each part. 

Check the log file at "C:\sources\new setup log.txt" on the target computer. 