*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Desktop
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${URL}=                         https://robotsparebinindustries.com/#/robot-order    # Orders application
${EXCEL_PATH_TO_DOWNLOADD}=     https://robotsparebinindustries.com/orders.csv    # Orders file locaiton

${PDF_IMAGE_TEMP_DIR}=          ${OUTPUT_DIR}${/}TEMP
${FINAL_RECEIPT_DIR}=           ${OUTPUT_DIR}${/}RECEIPTS
${ORDERS_ZIP_FILE_PATH}=        ${OUTPUT_DIR}${/}ORDERS_RECEIPTS.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Wait Until Keyword Succeeds    5x    1s    Fill the form    ${row}
        Download and store the receipt    ${row}[Order number]
        Order for another robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Output Directories Setup
    ${temp_dir_exists}=    Does Directory Exist    ${PDF_IMAGE_TEMP_DIR}
    ${final_receipts_exists}=    Does Directory Exist    ${FINAL_RECEIPT_DIR}
    ${zip_file_exits}=    Does Directory Exist    ${ORDERS_ZIP_FILE_PATH}

    IF    ${temp_dir_exists} == ${True}
        Empty Directory    ${PDF_IMAGE_TEMP_DIR}
    ELSE
        Create Directory    ${PDF_IMAGE_TEMP_DIR}
    END

    IF    ${final_receipts_exists} == ${True}
        Empty Directory    ${FINAL_RECEIPT_DIR}
    ELSE
        Create Directory    ${FINAL_RECEIPT_DIR}
    END

    IF    ${zip_file_exits} == ${True}
        Remove Directory    ${ORDERS_ZIP_FILE_PATH}
    END

Open the robot order website
    Open Available Browser    ${URL}    headless=${True}

Close the annoying modal
    Click Button    OK
    Wait Until Page Contains Element    id:head

Get Orders
    Output Directories Setup
    Download    ${EXCEL_PATH_TO_DOWNLOADD}    overwrite=True
    ${orders_table}=    Read table from CSV    orders.csv    dialect=excel
    RETURN    ${orders_table}

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[type='number']    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Element When Clickable    id:order    # Submit order
    Wait Until Page Contains Element    id:receipt    # Wait until receipt load

Download and store the receipt
    [Arguments]    ${order_number}
    ${receipt}=    Store the order receipt as a PDF file    ${order_number}
    ${screenshot}=    Take a screenshot of the robot image    ${order_number}
    Embed the robot screenshot to the receipt PDF file    ${receipt}    ${screenshot}    ${order_number}

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${PDF_IMAGE_TEMP_DIR}${/}OrderNumger${order_number}.pdf
    RETURN    ${PDF_IMAGE_TEMP_DIR}${/}OrderNumger${order_number}.pdf

Take a screenshot of the robot image
    [Arguments]    ${order_number}
    ${robot_image}=    Capture Element Screenshot
    ...    css:div[id='robot-preview-image']
    ...    ${PDF_IMAGE_TEMP_DIR}${/}RobotImage${order_number}.png
    RETURN    ${PDF_IMAGE_TEMP_DIR}${/}RobotImage${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${receipt}    ${screenshot}    ${order_number}
    Create File    ${FINAL_RECEIPT_DIR}${/}${order_number}.pdf
    ${Opened_pdf_receipt}=    Open Pdf    ${FINAL_RECEIPT_DIR}${/}${order_number}.pdf
    ${files}=    Create List    ${receipt}    ${screenshot}:align=center
    Add Files To Pdf    ${files}    ${FINAL_RECEIPT_DIR}${/}${order_number}.pdf
    Close All Pdfs

Archive output PDFs
    ${zip_file_name}=    Set Variable    ${ORDERS_ZIP_FILE_PATH}
    Archive Folder With Zip
    ...    ${FINAL_RECEIPT_DIR}
    ...    ${zip_file_name}

Order for another robot
    Click Button When Visible    id:order-another

Close RobotSpareBin Browser
# clenaing directories
    Empty Directory    ${PDF_IMAGE_TEMP_DIR}
    Empty Directory    ${FINAL_RECEIPT_DIR}
# closing browserss
    Close All Browsers
