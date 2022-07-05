*** Settings ***
Documentation       Certificate example robot
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory
    Get URL from vault and open the robot order website
    ${orderfileurl}=    Get the orders file url from the user
    Download the orders file    ${orderfileurl}
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Wait Until Keyword Succeeds     10x     0.5s    Preview order
        Wait Until Keyword Succeeds     10x     0.5s    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${order}
        ${screenshot}=    Take a screenshot of the robot    ${order}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another
    END
    Create a ZIP file of the receipts

*** Keywords ***
Directory
    Create Directory    ${OUTPUT_DIR}${/}pdf_files

    Create Directory    ${OUTPUT_DIR}${/}png_files

Get URL from vault and open the robot order website

    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[url]

Get the orders file url from the user
    Add heading    Upload Orders File
    Add text input    name=fileurl    label=Upload the Url of the Excel file with orders data    placeholder=Orders url

    ${response}=    Run dialog

    [Return]    ${response.fileurl}

Download the orders file
    #https://robotsparebinindustries.com/#/robot-order
    [Arguments]    ${orderfileurl}
    Download    ${orderfileurl}    overwrite=True

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Submit order
    Wait Until Element Is Enabled    id:preview
    Click Button    Order

    #Si no lo contiene falla la keywork y hace otra prueba
    Page Should Contain Element    id:receipt

Preview order
    Wait Until Element Is Enabled    id:order
    Click Button    Preview

    Page Should Contain Element    id:robot-preview-image

Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:order-completion
    ${receipt_result}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_result}    ${OUTPUT_DIR}${/}pdf_files${/}receipt_result${order}[Order number].pdf

    [Return]    ${OUTPUT_DIR}${/}pdf_files${/}receipt_result${order}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}png_files${/}robot_result${order}[Order number].png

    [Return]    ${OUTPUT_DIR}${/}png_files${/}robot_result${order}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    Open PDF    ${pdf}
    ${file_list}=    Create List    ${screenshot}
    Add Files To Pdf    ${file_list}    ${pdf}    True

    Close All Pdfs

Order another
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}pdf_files    ${OUTPUT_DIR}${/}receipts.zip


