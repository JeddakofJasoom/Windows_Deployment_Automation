<#
.SYNOPSIS
    Removes installed and provisioned Appx packages in Windows 10.
.DESCRIPTION
    To simplify the user experience and to streamline the configuration of Windows this script removes unneccesary Windows 10 apps.  These have been sorted into 4 categories:
    
    Home = Computers used in a home setting.  The difference between this and the ones below is this keeps the Xbox apps, and Mail app as they make sense on a personal computer.
    Named = Computers that are normally used by a single person in a typical office environment. Or at least typical where I work.
    Shared = Computers that are normally shared by multiple people with shared logins and have more direct functions (Lab PC, HR Kiosk, Conference Room PC etc.)
    Server = Computers that are used in a server type function, running Windows 10, and not used as a desktop PC. (Manufacturing floor PC, badge printing system etc.)
    
    Note that these lists are cumulative.
    Home = Home list
    Named = Home + Named lists
    Shared = Home + Named + Shared lists
    Server = Named + Shared + Server lists

    Suggest putting this in a computer based GPO login script
.EXAMPLE
    PS C:\>.\Remove-Win10Apps.ps1
    Removes all apps from the default home list asking for confirmation for each found app. Writes log to 'C:\Logs\Remove-Win10Apps.log'.
.EXAMPLE
    PS C:\>.\Remove-Win10Apps.ps1 -LogPath '\\server\share\appremoval.log'
    Removes all apps from the default home list asking for confirmation for each found app. Writes log to '\\server\share\appremoval.log'.
.EXAMPLE
    PS C:\>.\Remove-Win10Apps.ps1 -PCType "Shared" -Whatif
    Won't remove but just list all apps from the combined default home, named, and then shared list that it's found.
.EXAMPLE
    PS C:\>.\Remove-Win10Apps.ps1 -PCType "Server" -Confirm:$false
    Removes all apps from the default home, named, shared, and server list without prompting for confirmation. Writes log to 'C:\Logs\Remove-Win10Apps.log'.
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    More than just inspiration taken from the following
    https://github.com/W4RH4WK/Debloat-Windows-10/blob/master/scripts/remove-default-apps.ps1
    http://guidestomicrosoft.com/2016/08/26/simple-function-for-logging-powershell-script/
#>


#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
    # Specifies the list of apps from Home (the least removed) to Server (the most removed)
    [ValidateSet("Home", "Named", "Shared", "Server")]
    [String]$PCType = "Home",
    # Enter the full path to where you'd like the script to log it's changes. 
    [parameter(Mandatory = $false)]
    [ValidateScript( {
            if ($_ -notmatch "(\.log)") {
                throw "The file specified in the path argument must be of the type .log"
            }
            return $true 
        })]
    [System.IO.FileInfo]$LogPath = 'C:\Logs\Remove-Win10Apps.log',
    # Lists the entries in the different PCTypes depending on what's selected and closes
    [switch]$List
)


begin {
    function Write-Log {
        param(
            # Enter text you'd like to display on a single line in the log.
            [parameter(Mandatory = $true)]
            [string]$Text,
            [parameter(Mandatory = $true)]
            # Enter the severity of the log entry.
            [ValidateSet("WARNING", "ERROR", "INFO")]
            [string]$Type,
            # Specifies the path to save the log file to.
            [ValidateScript( {
                    if ($_ -notmatch "(\.log)") {
                        throw "The file specified in the path argument must be of the type .log"
                    }
                    return $true 
                })]
            # Sets the path to the log file to C:\Logs\ + the name of the script running the function + .log
            [System.IO.FileInfo]$Path = 'C:\Logs\' + ([io.path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)) + '.log'

        )
        #Makes sure that it updates the "exists" property or else the file keeps getting recreated.
        $Path.Refresh()
        if ($Path.Exists -eq $false) {
            New-Item -ItemType 'file' -Path $Path -Force
        }
        [string]$LogMessage = [System.String]::Format("[$(Get-Date)] -"), $Type, $Text
        Add-Content -Path $Path -Value $LogMessage
    }

    Write-Log -Text "Starting Remove-Win10Apps script with -PCType $PCType and -LogPath $LogPath" -Type 'INFO' -Path $LogPath
 
    #Checks OS is Windows 10 and terminates if it's not.
    if ([Environment]::OSVersion.Version.Major -lt '10') {
        Write-Warning 'Exiting...you must be running a version ofy Windows 10 to run this script.'
        Write-Log -Text 'Exiting...you must be running a version of Windows 10 to run this script.' -Type 'ERROR' -Path $LogPath
        Exit
    }

    #Region App Listing
    $AppsHomePC = @(
        "Microsoft.3DBuilder"                       #3D Builder - https://www.microsoft.com/en-us/p/3d-builder/9wzdncrfj3t6 - View, create, and personalize 3D objects using 3D Builder.
        "Microsoft.Appconnector" 
        "Microsoft.BingFinance"                     #MSN Money - https://www.microsoft.com/en-us/p/msn-money/9wzdncrfhv4v - Finance simplified. Know more about your money with the world’s best financial news and data. Grow your finances with handy tools and calculators, any time and anywhere.
        "Microsoft.BingFoodAndDrink"                #MSN Food & Drink - NA (Discontinued)
        "Microsoft.BingHealthAndFitness"            #MSN Health & Fitness - NA (Discontinued)
        "Microsoft.BingNews"                        #Microsoft News - https://www.microsoft.com/en-us/p/microsoft-news/9wzdncrfhvfw - Delivers breaking news and trusted, in-depth reporting from the world's best journalists.
        "Microsoft.BingSports"                      #MSN Sports - https://www.microsoft.com/en-us/p/msn-sports/9wzdncrfhvh4 - The MSN Sports app is packed with live scores & in-depth game experiences for more than 150 leagues.
        "Microsoft.BingTranslator"                  #Translator - https://www.microsoft.com/en-us/p/translator/9wzdncrfj3pg - Microsoft Translator enables you to translate text and speech, have translated conversations, and even download AI-powered language packs to use offline.
        "Microsoft.BingTravel"                      #MSN Travel - NA (Discontinued)
        "Microsoft.BingWeather"                     #MSN Weather - https://www.microsoft.com/en-us/p/msn-weather/9wzdncrfj3q2 - The best way to plan your day. Get the latest weather conditions, whether you're hitting the slopes, or the beach, or checking the forecast for your commute. See accurate 10-day and hourly forecasts for whatever you do.
        "Microsoft.CommsPhone"
        "Microsoft.ConnectivityStore"
        "Microsoft.FreshPaint"                      #Fresh Paint - https://www.microsoft.com/en-us/p/fresh-paint/9wzdncrfjb13 - Unleash your inner creative with Fresh Paint – the ultimate canvas for your big ideas. Fresh Paint is a fun and easy to use painting app with the right tools for artists of all ages. 
        "Microsoft.GetHelp"                         #Get Help 
        "Microsoft.Getstarted"                      #Microsoft Tips
        "Microsoft.Messaging"                       #Microsoft Messaging - https://www.microsoft.com/en-us/p/microsoft-messaging/9wzdncrfjbq6 - Microsoft Messaging enables, quick, reliable SMS, MMS and RCS messaging from your phone. To get started, select Messaging from the All apps list.
        "Microsoft.Microsoft3DViewer"               #3D Viewer - https://www.microsoft.com/en-us/p/3d-viewer/9nblggh42ths - Easily view 3D models and animations in real-time. 3D Viewer lets you view 3D models with lighting controls, inspect model data and visualize different shading modes. In Mixed Reality mode, combine the digital and physical. Push the boundaries of reality and capture it all with a video or photo to share.
        "Microsoft.MicrosoftOfficeHub"              #Office - https://www.microsoft.com/en-us/p/office/9wzdncrd29v9 - The Office app enables you to get the most out of Office by helping you find all your Office apps and files in one place so you can jump quickly into your work.
        "Microsoft.MicrosoftPowerBIForWindows"      #Power BI - https://www.microsoft.com/en-us/p/power-bi/9nblgggzlxn1 - Monitor your most important business data, directly from your device. Get a quick overview with intuitive, at-a-glance visuals, or dive deep into your data and discover new insights with interactive dashboards and reports. 
        "Microsoft.MicrosoftSolitaireCollection"    #Microsoft Solitaire Collection - https://www.microsoft.com/en-us/p/microsoft-solitaire-collection/9wzdncrfhwd2 - Check out the new look and feel of Microsoft Solitaire Collection on Windows 10!
        "Microsoft.MinecraftUWP"                    #Minecraft - NA (Discontinued)
        "Microsoft.MixedReality.Portal"             #Mixed Reality Portal - https://www.microsoft.com/en-us/p/mixed-reality-portal/9ng1h8b3zc7m - iscover Windows Mixed Reality and dive into more than 3,000 games and VR experiences from Steam®VR and Microsoft Store. Get extraordinary access to live sports and entertainment and connect with others in the ultimate high-octane VR gaming experience. 
        "Microsoft.NetworkSpeedTest"                #Network Speed Test - https://www.microsoft.com/en-us/p/network-speed-test/9wzdncrfhx52 - Network Speed Test measures your network delay, download speed and upload speed.
        "Microsoft.Office.Sway"                     #Sway - https://www.microsoft.com/en-us/p/sway/9wzdncrd2g0j - Create visually striking newsletters, presentations, and documentation in minutes.
        "Microsoft.OfficeLens"                      #Office Lens - https://www.microsoft.com/en-us/p/office-lens/9wzdncrfj3t8 - Office Lens trims, enhances, and makes pictures of whiteboards and docs readable. You can use Office Lens to convert images to PDF, Word and PowerPoint files, and you can even save images to OneNote or OneDrive.     
        "Microsoft.OneConnect"                      #Paid Wi-Fi & Cellular or Mobile Plans#                          
        "Microsoft.People"                          #Microsoft People - https://www.microsoft.com/en-us/p/microsoft-people/9nblggh10pg8 - People in Windows 10 puts all the ways you connect with all your friends, family, colleagues, and acquaintances in one place, so it’s faster than ever to keep in touch. Check out what your people are up to across the services they use and choose how you want to connect with them.
        "Microsoft.Print3D"                         #Print 3D - https://www.microsoft.com/en-us/p/print-3d/9pbpch085s3s - Quickly and easily prepare objects for 3D printing on your PC. With support for Wifi printers, you can 3D print from anywhere on your network. Get the best out of your printer by tuning many custom settings like the extruder temperature and printing speed.
        "Microsoft.SkypeApp"                        #Skype - https://www.microsoft.com/en-us/p/skype/9wzdncrfj364 - Skype keeps the world talking. Say “hello” with an instant message, voice or video call – all for free, no matter what device they use Skype on. Skype is available on phones, tablets, PCs, and Macs.
        "Microsoft.Wallet"                          #Microsoft Pay#
        "Microsoft.Whiteboard"                      #Whiteboard - https://www.microsoft.com/en-us/p/microsoft-whiteboard/9mspc6mp8fm4 - Meet the freeform digital canvas where ideas, content, and people come together.
        "Microsoft.WindowsFeedbackHub"              #Feedback Hub - https://www.microsoft.com/en-us/p/feedback-hub/9nblggh4r32n - Help us make Windows better! Provide feedback about Windows and apps by sharing your suggestions or problems. If you want to be even more involved, then join the Windows Insider program and keep up with the latest alerts and announcements, rate the builds, participate in feedback Quests, and earn badges.
        "Microsoft.WindowsMaps"                     #Windows Maps - https://www.microsoft.com/en-us/p/windows-maps/9wzdncrdtbvb - Maps is your guide to everywhere. Find your way with voice navigation and turn-by-turn driving, transit, and walking directions. Search for places to get directions, business info, and reviews. Download maps to use when you’re offline. Tour the world virtually with breathtaking aerial imagery and 360 degree street-level views. Plus, you get the same experience across all your Windows 10 PCs and phones.
        "Microsoft.WindowsPhone"
        "Microsoft.WindowsReadingList"              #Windows Reading List - https://www.microsoft.com/en-us/p/windows-reading-list/9wzdncrfj3rx - Do you ever run out of time to read articles or watch videos you’ve found online? With Reading List, you can easily track and manage all of the content you want to get back to later in a beautiful display. You can share content to your list from the web or from other apps and easily come back to it when you have more time. Whatever you like to read or watch, the app makes it easy to save, find and get back to things you like, listing content you've saved in chronological order.
        "Microsoft.YourPhone"                       #Your Phone - https://www.microsoft.com/en-us/p/your-phone/9nmpj99vjbwv - You love your phone. So does your PC. Get instant access to everything you love on your phone, right on your PC. Reply to your text messages with ease, stop emailing yourself photos, and receive and manage your phone’s notifications on your PC.
    
        #3rd Party
        "2FE3CB00.PicsArt-PhotoStudio"
        "46928bounde.EclipseManager"                #Eclipse
        "613EBCEA.PolarrPhotoEditorAcademicEdition"
        "6Wunderkinder.Wunderlist"
        "7EE7776C.LinkedInforWindows"
        "89006A2E.AutodeskSketchBook"
        "9E2F88E3.Twitter"
        "A278AB0D.DisneyMagicKingdoms"
        "A278AB0D.MarchofEmpires"
        "ActiproSoftwareLLC.562882FEEB491"          #Code Writer
        "AdobeSystemIncorporated.AdobePhotoshop"    #Photoshop Express
        "CAF9E577.Plex"                             #Plex
        "ClearChannelRadioDigital.iHeartRadio"
        "D52A8D61.FarmVille2CountryEscape"
        "D5EA27B7.Duolingo-LearnLanguagesforFree"   #Duolingo
        "DB6EA5DB.CyberLinkMediaSuiteEssentials"
        "DolbyLaboratories.DolbyAccess"
        "Drawboard.DrawboardPDF"
        "Facebook.Facebook"                         #Facebook
        "Fitbit.FitbitCoach"
        "flaregamesGmbH.RoyalRevolt2"
        "Flipboard.Flipboard"                       #Flipboard
        "GAMELOFTSA.Asphalt8Airborne"
        "KeeperSecurityInc.Keeper"
        "king.com.*"
        "king.com.BubbleWitch3Saga"
        "king.com.CandyCrushFriends"
        "king.com.CandyCrushSaga"
        "king.com.CandyCrushSodaSaga"
        "NORDCURRENT.COOKINGFEVER"
        "PandoraMediaInc.29680B314EFC2"             #Pandora
        "Playtika.CaesarsSlotsFreeCasino"
        "ShazamEntertainmentLtd.Shazam"
        "TheNewYorkTimes.NYTCrossword"
        "ThumbmunkeysLtd.PhototasticCollage"
        "TuneIn.TuneInRadio"
        "WinZipComputing.WinZipUniversal"
        "XINGAG.XING"
    )

    $AppsNamedPC = @(
        "microsoft.windowscommunicationsapps"       #Mail and Calendar - https://www.microsoft.com/en-us/p/mail-and-calendar/9wzdncrfhvqm - The Mail and Calendar apps help you stay up to date on your email, manage your schedule and stay in touch with people you care about the most. Designed for both work and home, these apps help you communicate quickly and focus on what’s important across all your accounts. Supports Office 365, Exchange, Outlook.com, Gmail, Yahoo! and other popular accounts.
        "Microsoft.XboxApp"                         #Xbox Console Companion - https://www.microsoft.com/en-us/p/xbox-console-companion/9wzdncrfjbd8 - The Xbox app brings together your friends, games, and accomplishments across Xbox One and Windows 10 devices. The best multiplayer gaming just got better.
        "Microsoft.XboxGameOverlay"                 #Xbox Game Bar - https://www.microsoft.com/en-us/p/xbox-game-bar/9nzkpstsnw4p - Win+G it with Xbox Game Bar, the customizable, gaming overlay built into Windows 10. Xbox Game Bar works with most PC games, giving you instant access to widgets for screen capture and sharing, finding new teammates with LFG, and chatting with Xbox friends across Xbox console, mobile, and PC—all without leaving your game.
        "Microsoft.XboxGamingOverlay"               #Xbox Gaming Overlay
        "Microsoft.XboxIdentityProvider"            #Xbox Identity Provider
        "Microsoft.XboxSpeechToTextOverlay"

        #3rd Party
        "4DF9E0F8.Netflix"                          #Netflix - https://www.microsoft.com/en-us/p/netflix/9wzdncrfj3tj - Netflix has something for everyone. Watch TV shows and movies recommended just for you, including award-winning Netflix original series, movies, and documentaries. There’s even a safe watching experience just for kids with family-friendly entertainment.
        "SpotifyAB.SpotifyMusic"                    #Spotify - https://www.microsoft.com/en-us/p/spotify-music/9ncbcszsjrsb - Love music? Play your favorite songs and albums free on Windows 10 with Spotify.
    )

    $AppsSharedPC = @(
        "Microsoft.Office.OneNote"                  #OneNote - https://www.microsoft.com/en-us/p/onenote/9wzdncrfhvjl - OneNote is your digital notebook for capturing and organizing everything across your devices. Jot down your ideas, keep track of classroom and meeting notes, clip from the web, or make a to-do list, as well as draw and sketch your ideas.
        "Microsoft.Todos"                           #Microsoft To Do - https://www.microsoft.com/en-us/p/microsoft-to-do-lists-tasks-reminders/9nblggh5r558 - Got something on your mind? Get Microsoft To Do. Whether you want to increase your productivity, decrease your stress levels, or just free up some mental space, Microsoft To Do makes it easy to plan your day and manage your life.
        "Microsoft.WindowsCamera"                   #Windows Camera - https://www.microsoft.com/en-us/p/windows-camera/9wzdncrfjbbg - The Camera app is faster and simpler than ever. Just point and shoot to take great pictures automatically on any PC or tablet running Windows 10.
        "Microsoft.WindowsSoundRecorder"            #Windows Voice Recorder - https://www.microsoft.com/en-us/p/windows-voice-recorder/9wzdncrfhwkn - Record sounds, lectures, interviews, and other events. Mark key moments as you record, edit, or play them back.
    )

    $AppsServerPC = @(
        "Microsoft.MSPaint"                         #Paint 3D - https://www.microsoft.com/en-us/p/paint-3d/9nblggh5fv99 - Whether you’re an artist or just want to try out some doodles–Paint 3D makes it easy to unleash your creativity and bring your ideas to life. Classic Paint has been reimagined, with an updated look and feel and a ton of new brushes and tools. And now, create in every dimension. Make 2D masterpieces or 3D models that you can play with from all angles.
        "Microsoft.MicrosoftStickyNotes"            #Microsoft Sticky Notes - https://www.microsoft.com/en-us/p/microsoft-sticky-notes/9nblggh4qghw - Need to remember something for later? Use Microsoft Sticky Notes. They're the simple way to quickly save something for later, so you can stay in the flow. With Sticky Notes, you can create notes, type, ink or add a picture, add text formatting, stick them to the desktop, move them around there freely, close them to the Notes list, and sync them across devices and apps like OneNote Mobile, Microsoft Launcher for Android, and Outlook for Windows.      
        "Microsoft.WindowsAlarms"                   #Windows Alarms & Clock - https://www.microsoft.com/en-us/p/windows-alarms-clock/9wzdncrfj3pr - A combination of alarm clock, world clock, timer, and stopwatch. Set alarms and reminders, check times around the world, and time your activities, including laps and splits.
        "Microsoft.WindowsCalculator"               #Windows Calculator - https://www.microsoft.com/en-us/p/windows-calculator/9wzdncrfhvn5 - A simple yet powerful calculator that includes standard, scientific, and programmer modes, as well as a unit converter. It's the perfect tool to add up a bill, convert measurements in a recipe or other project, or complete complex math, algebra, or geometry problems. Calculator history makes it easy to confirm if you've entered numbers correctly.
        "Microsoft.Windows.Photos"                  #Microsoft Photos -https://www.microsoft.com/en-us/p/microsoft-photos/9wzdncrfjbh4 - View and edit your photos and videos, make movies, and create albums. Try video remix to instantly create a video from photos and videos you select. Use the video editor for fine-tuned adjustments — change filters, text, camera motion, music, and more. You can even add 3D effects like butterflies, lasers, or explosions that magically appear in your video.
        "Microsoft.ZuneMusic"                       #Groove Music - https://www.microsoft.com/en-us/p/groove-music/9wzdncrfj3pt - Listen to your favorite music in Groove on your Windows, iOS, and Android devices. Create a playlist with music you've purchased or uploaded to OneDrive or pick your background music on Xbox One.
        "Microsoft.ZuneVideo"                       #Movies & TV - https://www.microsoft.com/en-us/p/movies-tv/9wzdncrfj3p2 - All your movies and TV shows, all in one place, on all your devices. Movies & TV brings you the latest entertainment in one simple, fast, and elegant app on Windows. On your PC and Windows Mobile, the app lets you play and manage videos from your personal collection. On all your devices, you can use the app to browse and play movies and TV shows you’ve purchased from the Store.
    )

    <#---APPS THAT SHOULD NEVER BE REMOVED FOR ANY TYPE OF WINDOWS PC
    $RemainingAppsForReference = @(
    #"1527c705-839a-4832-9118-54d4Bd6a0c89"         #File Picker - App which cannot be removed using Remove-AppxPackage
    #"c5e2524a-ea46-4f67-841f-6a9465d9d515"         #File Explorer - App which cannot be removed using Remove-AppxPackage
    #"E2A4F912-2574-4A75-9BB0-0D023378592B"         #App Resolver UX - App which cannot be removed using Remove-AppxPackage
    #"F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE"         #Add Suggested Folders To Library - App which cannot be removed using Remove-AppxPackage
    #"InputApp"                                     #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.AAD.BrokerPlugin"                   #Microsoft.AAD.Broker.Plugin - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.AccountsControl"                    #Microsoft.AccountsControl - App which cannot be removed using Remove-AppxPackage                    
    #"Microsoft.Advertising.Xaml"                   #Microsoft.Advertising - Framework apps which other apps depend on
    #"Microsoft.AsyncTextService"                   #Microsoft.AsyncTextService - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.BioEnrollment"                      #Hello setup UI - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.CredDialogHost"                     #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.DesktopAppInstaller"                #App Installer - Keeping just in case we ever want to deploy UWP apps
    #'Microsoft.DirectXRuntime'                     #? - Framework apps which other apps depend on
    #"Microsoft.ECApp"                              #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.HEIFImageExtension"                 #HEIF Image Extensions - Keeping so HEIF compressed images can be opened
    #"Microsoft.LockApp"                            #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.MicrosoftEdge"                      #Microsoft Edge - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.MicrosoftEdgeDevToolsClient"        #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.NET.Native.Framework.1.3"           #Framework app which other apps depend on
    #"Microsoft.NET.Native.Framework.1.6"           #Framework app which other apps depend on       
    #"Microsoft.NET.Native.Framework.1.7"           #Framework app which other apps depend on
    #"Microsoft.NET.Native.Framework.2.1"           #Framework app which other apps depend on
    #"Microsoft.NET.Native.Framework.2.2"           #Framework app which other apps depend on
    #"Microsoft.NET.Native.Runtime.1.4"             #Framework app which other apps depend on
    #"Microsoft.NET.Native.Runtime.1.6"             #Framework app which other apps depend on
    #"Microsoft.NET.Native.Runtime.1.7"             #Framework app which other apps depend on
    #"Microsoft.NET.Native.Runtime.2.2"             #Framework app which other apps depend on
    #"Microsoft.PPIProjection"                      #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.RemoteDesktop"                      #Remote Desktop - Functionality, expected to be there
    #"Microsoft.Services.Store.Engagement"          #Framework app which other apps depend on
    #"Microsoft.StorePurchaseApp"                   #Store Purchase App#Framework app which other apps depend on (not really but needed for store to function)
    #"Microsoft.UI.Xaml.2.0"                        #Framework app which other apps depend on
    #"Microsoft.UI.Xaml.2.1"                        #Framework app which other apps depend on
    #"Microsoft.UI.Xaml.2.2"                        #Framework app which other apps depend on
    #"Microsoft.VCLibs.120.00.Universal"            #Framework app which other apps depend on
    #"Microsoft.VCLibs.140.00"                      #Framework app which other apps depend on
    #"Microsoft.VCLibs.140.00.UWPDesktop"           #Framework app which other apps depend on
    #"Microsoft.VP9VideoExtensions"                 #Keeping so VP9 media can be played back
    #"Microsoft.WebMediaExtensions"                 #Web Media Extensions#basic functionality
    #"Microsoft.WebpImageExtension"                 #Webp Image Extension#basic functionality
    #"Microsoft.Win32WebViewHost"                   #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.Apprep.ChxApp"              #? - App which cannot be removed using Remove-AppxPackage    
    #"Microsoft.Windows.AssignedAccessLockApp"      #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.CapturePicker"              #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.CloudExperienceHost"        #? - App which cannot be removed using Remove-AppxPackage    
    #"Microsoft.Windows.ContentDeliveryManager"     #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.Cortana"                    #Cortana - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.NarratorQuickStart"         #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.OOBENetworkCaptivePortal"   #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.OOBENetworkConnectionFlow"  #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.ParentalControls"           #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.PeopleExperienceHost"       #People Hub - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.PinningConfirmationDialog"  #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.SecHealthUI"                #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.SecureAssessmentBrowser"    #? - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.ShellExperienceHost"        #Start - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.Windows.XGpuEjectDialog"            #? - apps which cannot be removed using Remove-AppxPackage
    #"Microsoft.WindowsFeedback"                    #Windows Feedback - App which cannot be removed using Remove-AppxPackage
    #"Microsoft.WindowsStore"                       #Microsoft Store -Vital functionality
    #"Microsoft.Xbox.TCUI"                          #? - App shouldn't be removed as it causes issues with Windows Photos, Windows Hello and others
    #"Microsoft.XboxGameCallableUI"                 #? - App which cannot be removed using Remove-AppxPackage
    #"Windows.ContactSupport"                       #Contact Support - App which cannot be removed using Remove-AppxPackage
    #"Windows.CBSPreview"                           #? - App which cannot be removed using Remove-AppxPackage
    #"windows.immersivecontrolpanel"                #Settings - App which cannot be removed using Remove-AppxPackage
    #"Windows.PrintDialog"                          #Print UI - App which cannot be removed using Remove-AppxPackage
    ) #>
    #EndRegion App Listing

    switch ($PCType) {
        Home { $AllAppsToRemove = $AppsHomePC }
        Named { $AllAppsToRemove = $AppsHomePC + $AppsNamedPC }
        Shared { $AllAppsToRemove = $AppsHomePC + $AppsNamedPC + $AppsSharedPC }
        Server { $AllAppsToRemove = $AppsHomePC + $AppsNamedPC + $AppsSharedPC + $AppsServerPC }
    }
    

    If ($list) {
        Write-Output "LIST OF APPS IN -PCType $PCType"
        ForEach ($App in $AllAppsToRemove) {
            Write-Output $App
        }
        Break
    }

    $ProvisionedAppxPackages = Get-AppxProvisionedPackage -Online
    $ProvisionedAppxPackagesToRemove = @()
    
    #Determine what apps that are provisioned on this PC to be removed by comparing against the list (Home, Named, Shared, Server)
    foreach ($Appx in $AllAppsToRemove) {
        $ProvisionedAppxPackagesToRemove += ($ProvisionedAppxPackages | Where-Object { $_.DisplayName -eq $Appx })
    }

    $InstalledAppxPackages = Get-AppxPackage -AllUsers
    $InstalledAppxPackagesToRemove = @()

    #Determine what apps that are installed on this PC to be removed by comparing against the list (Home, Named, Shared, Server)
    foreach ($Appx in $AllAppsToRemove) {
        $InstalledAppxPackagesToRemove += ($InstalledAppxPackages | Where-Object { $_.Name -eq $Appx })
    }
}

process {
    If ($ProvisionedAppxPackagesToRemove.length -ge 1) {
        Write-Output "***Removing select provisioned appx packages for this machine...***"
        Write-Log -Text 'Removing select provisioned appx packages for this machine' -Type 'INFO' -Path $LogPath
        foreach ($ProvisionedAppx in $ProvisionedAppxPackagesToRemove) {
            if ($PSCmdlet.ShouldProcess($ProvisionedAppx.DisplayName, 'Remove-AppxProvisionedPackage -Online -AllUsers')) {
                try {
                    $ProvisionedAppx | Remove-AppxProvisionedPackage -Online -AllUsers -Verbose -ErrorAction Continue
                    Write-Output $("Removed " + $ProvisionedAppx.DisplayName)
                    Write-Log -Text $("Removed " + $ProvisionedAppx.DisplayName) -Type 'INFO' -Path $LogPath
                }
                catch {
                    Write-Warning $('Unable to remove ' + $ProvisionedAppx.DisplayName)
                    Write-Log -Text $('Unable to remove ' + $ProvisionedAppx.DisplayName) -Type 'WARNING' -Path $LogPath
                }
            }
        }
    }
    else {
        Write-Output "***No provisioned appx packages from your selection were found for this machine...***"
        Write-Log -Text 'No provisioned appx packages from your selection were found for this machine' -Type 'INFO' -Path $LogPath
    }

    If ($InstalledAppxPackagesToRemove.length -ge 1) {
        Write-Output "***Removing select installed appx packages for this machine...***"
        Write-Log -Text 'Removing select installed appx packages for this machine' -Type 'INFO' -Path $LogPath
        foreach ($InstalledAppx in $InstalledAppxPackagesToRemove) {
            if ($PSCmdlet.ShouldProcess($InstalledAppx.Name, 'Remove-AppxPackage -AllUsers')) {
                try {
                    $InstalledAppx | Remove-AppxPackage -AllUsers -Verbose -ErrorAction Continue
                    Write-Output $("Removed " + $InstalledAppx.Name)
                    Write-Log -Text $("Removed " + $InstalledAppx.Name) -Type 'INFO' -Path $LogPath
                }
                catch {
                    Write-Warning $('Unable to remove ' + $InstalleddAppx.Name)
                    Write-Log -Text $('Unable to remove ' + $InstalleddAppx.Name) -Type 'WARNING' -Path $LogPath
                }
            } 
        }
    }
    else {
        Write-Output "***No installed appx packages from your selection were found for this machine...***"
        Write-Log -Text 'No installed appx packages from your selection were found for this machine' -Type 'INFO' -Path $LogPath
    }
}

end {
    Write-Log -Text 'Stopping Remove-Win10Apps script as it has finished running' -Type 'INFO' -Path $LogPath
}