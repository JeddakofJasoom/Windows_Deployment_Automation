@echo off 

powercfg /hibernate off
rmdir c:\recovery /s /q
rmdir c:\drivers /s /q
rmdir c:\$winreagent /s /q
rmdir c:\dell /s /q
rmdir c:\apps /s /q
del c:\temp\*.* /s /q
del c:\windows\temp\*.* /s /q
