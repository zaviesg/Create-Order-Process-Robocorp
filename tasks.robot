*** Settings ***
Documentation       Create Order Process.

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             RPA.Tasks


*** Variables ***
${Excel_URL}        https://robotsparebinindustries.com/orders.csv
${ORDER_URL}        https://robotsparebinindustries.com/#/robot-order
@{ORDERS}
${LEGS}             //input[contains(@id,"168")]
${pdf}
${screenshot}


*** Tasks ***
Create Order Process.
    Download the Excel file
    Read CSV as Table
    Close Annoying Modal
    Fill the form using the data from Excel
    Close the Browser
    Create ZIP file for receipts


*** Keywords ***
Download the Excel file
    Download    ${Excel_URL}    target_file=${OUTPUT_DIR}${/}data.csv
    ...    overwrite=True

Read CSV as Table
    @{ORDERS}=    Read table from CSV    data.csv
# Iteration for each row in Order.csv then log each order
    FOR    ${order}    IN    @{ORDERS}
        Log    ${order}
    END

#Launch Browser, close pop-up window

Close Annoying Modal
    Open Available Browser    ${ORDER_URL}
    Maximize Browser Window
    Wait Until Page Contains Element    id:root
    Click Button    OK

Fill the form
    [Arguments]    ${order}
#For each row in Excel file, fill the form & preview
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    ${LEGS}    ${order}[Legs]
    Input Text    address    ${order}[Address]

#Preview the robot
    Click Button    preview
    TRY
        Click Button    order
        Wait Until Element Is Visible    receipt
    EXCEPT
        Wait And Click Button    order
        #Wait Until Keyword Succeeds    15x    2s    Click Button    order
    FINALLY
        Wait Until Page Contains Element    receipt
    END

    Mute Run On Failure    Fill the form    ${order}
    #Add Files To Pdf    ${OUTPUT_DIR}${/}${order}[Order number].png    ${order}[Order number].pdf
    Screenshot    receipt    ${OUTPUT_DIR}${/}${order}[Order number].png
    Print To Pdf    ${OUTPUT_DIR}${/}${order}[Order number].pdf
    Click Button    order-another
    Click Button    OK
    Wait Until Page Contains Element    id:root

Fill the form using the data from Excel
    @{ORDERS}=    Read table from CSV    data.csv
    FOR    ${order}    IN    @{ORDERS}
        Fill the form    ${order}
    END

Close the Browser
    Close Browser

Create ZIP file for receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.Zip    include=*.pdf
