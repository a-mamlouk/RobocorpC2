*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...                 Author: https://github.com/a-mamlouk

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${url}=         https://robotsparebinindustries.com/#/robot-order
#${csv_url}=    https://robotsparebinindustries.com/orders.csv
${output}=      ${CURDIR}${/}output
${zip_file}     ${output}${/}pdf_archive.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_url}=    ask the user for some input
    Open the robot order website
    ${orders}=    Get orders    ${csv_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    ${url}    maximized=${True}

Get orders
    [Arguments]    ${csv_url}
    Download    ${csv_url}    overwrite=${True}
    ${table}=    Read table from CSV    ${CURDIR}${/}orders.csv
    RETURN    ${table}

Close the annoying modal
    Wait Until Element Is Visible    //div[@class='modal-header']
    Click Button    //button[normalize-space()='OK']

Fill the form
    [Arguments]    ${myrow}

    # Extract the values from the CSV

    Set Local Variable    ${head}    ${myrow}[Head]
    Set Local Variable    ${body}    ${myrow}[Body]
    Set Local Variable    ${legs}    ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]

    # Define local variables for the UI elements
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]

    # Input CSV data into the apprpriate path
    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}
    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    Wait Until Element Is Visible    //*[@id="preview"]
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Mute Run On Failure    Page Should Contain Element
    Click button    //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

Store the receipt as a PDF file
    [Arguments]    ${rowxx}

    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${pdf_path}    ${output}${/}receipts${/}${rowxx}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${pdf_path}

    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${rowxx}

    Wait Until Element Is Visible    (//div[@id='robot-preview-image'])[1]
    Set Local Variable    ${Sc_path}    ${output}${/}screenshots${/}${rowxx}.PNG
    Capture Element screenshot    (//div[@id='robot-preview-image'])[1]    ${Sc_path}

    RETURN    ${Sc_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${SC}    ${PDF}

    Add Watermark Image To PDF    ${SC}    ${PDF}    ${PDF}
    #Open Pdf    ${PDF}
    #@{file}=    Create List    ${SC}:align=center
    #Add Files To PDF    ${file}    ${PDF}    ${True}
    #Close Pdf    ${PDF}

Go to order another robot
    Click Button    //*[@id="order-another"]
    Sleep    1s

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${output}${/}receipts    ${zip_file}    recursive=True    include=*.pdf

ask the user for some input
    #Add heading    Insert URL
    #Add text input    URL    label=URL-Address
    #...    placeholder=Enter URL here
    #...    rows=1
    #${result}=    Run dialog
    #Insert URL${result.URL}
    #RETURN    ${result.URL}
    #########
    ${secret}=    Get Secret    url
    Log    ${secret}[CSV_url]
    RETURN    ${secret}[CSV_url]
