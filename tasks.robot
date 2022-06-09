*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem
Library    RPA.Robocloud.Secrets
Library    RPA.Dialogs

*** Variables ***
# ${csv_url}=     https://robotsparebinindustries.com/orders.csv
${CSV_PATH}=    ${OUTPUT_DIR}${/}orders.csv
# ${url}=         https://robotsparebinindustries.com/#/robot-order


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Get URL from the vault
    Open the robot order website    ${url}
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the annoying popup
        Fill the form    ${order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser and Clean Screenshots

*** Keywords ***
Get URL from the vault
    ${url}=    Get Secret    credentials
    RETURN    ${url}[url]

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Get Order CSV URL from User
    Add text input    csv_url    label=CSV URL
    ${response}=    Run dialog
    RETURN    ${response.csv_url}

Get orders
    ${csv_url}=    Get Order CSV URL from User
    Download    ${csv_url}    ${CSV_PATH}    overwrite=True
    ${orders}=    Read table from CSV    ${CSV_PATH}
    RETURN    ${orders}
    
Close the annoying popup
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview

Check Submission Success
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion

Submit the order
    Wait Until Keyword Succeeds    10x    1s    Check Submission Success

Go to order another robot
    # Wait Until Element Is Visible    id:receipt
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${order number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}order-${order number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}order-${order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order number}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}preview-${order number}.png
    RETURN    ${OUTPUT_DIR}${/}preview-${order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    # Close Pdf    ${pdf}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip

Close Browser and Clean Screenshots
    Close Browser
    Remove File    ${OUTPUT_DIR}${/}*.png