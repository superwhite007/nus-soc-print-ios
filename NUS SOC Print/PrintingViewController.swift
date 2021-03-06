//
//  PrintingViewController.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 17/8/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import Foundation
import UIKit

class PrintingViewController : HelperFunctionsYesNoAlertViewController, UITableViewDelegate, UITableViewDataSource{
    
    let TAG = "PrintingViewController"
    
    let CELL_IDENTIFIER = "PrintingViewTableCell"
    let CELL_ROW_ZERO_HEIGHT : CGFloat = 0
    let CELL_ROW_HEIGHT : CGFloat = 52
    let FORMAT_UPLOADING = "%@ of %@ (%.1f%%)"
    
    let DIALOG_YES = "Yes"
    let DIALOG_NO = "No"
    let DIALOG_TITLE = "Are you sure you want to cancel this print operation?"
    
    
    let ALERT_CANCEL_OPERATION_TAG = 24
    let ALERT_CONTINUE_DOC_UPLOAD_TAG = 25
    
    
    let HEADER_TEXT : Array<String> =
    ["Connecting to server"
        ,"Some housekeeping"
        ,"Uploading DOC converter"
        ,"Uploading PDF Formatter"
        ,"Uploading %@"
        ,"Converting to PDF"
        ,"Trim PDF to page %d to %d"
        ,"Formatting to %@ pages/sheet"
        ,"Converting to Postscript"
        ,"Sending to %@"]
    
    let POSITION_CONNECTING = 0
    let POSITION_HOUSEKEEPING = 1
    let POSITION_UPLOADING_DOC_CONVERTER = 2
    let POSITION_UPLOADING_PDF_CONVERTER = 3
    let POSITION_UPLOADING_USER_DOC = 4
    let POSITION_CONVERTING_TO_PDF = 5
    let POSITION_TRIM_PDF_TO_PAGE_RANGE = 6
    let POSITION_FORMATTING_PDF = 7
    let POSITION_CONVERTING_TO_POSTSCRIPT = 8
    let POSITION_SENDING_TO_PRINTER = 9
    let POSITION_COMPLETED = 10
    
    let CLOSE_TEXT = "Close"
    
    
    let PROGRESS_INDETERMINATE : Array<Bool> =
    [true
        ,true
        ,false
        ,false
        ,false
        ,true
        ,true
        ,true
        ,true
        ,true]
    
    
    
    
    let TEXT_INDETERMINATE = "This could take a while..."
    
    var printer : String!
    var pagesPerSheet : String!
    var filePath : NSURL!
    var filePathString : String!
    
    var startPageRange : Int = 0
    var endPageRange : Int = 0
    
    var currentProgress : Int = 0
    
    var operation : PrintingOperation?
    
    @IBOutlet weak var progressTable: UITableView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    
    
    var docConvSize : Int = 0
    var docConvUploaded : Int = 0
    
    var pdfConvSize : Int = 0
    var pdfConvUploaded : Int = 0
    
    var docToPrintSize : Int = 0
    var docToPrintUploaded : Int = 0
    
    
    
    var needToConvertDocToPDF : Bool = true
    var needToFormatPDF : Bool = true
    var needToTrimPDFToPageRange : Bool = false
    
    var filename : String!
    
    
    var semaphore : dispatch_semaphore_t?
    
    var continueWithDocumentUpload = false
    
    @IBAction func cancelButtonPressed(sender: UIButton) {
        if(operation == nil){
            cancelAndClose()
        } else {
            showCancelOperationAlert(DIALOG_TITLE, message: "", viewController: self)
        }
        
        
        
    }
    
    func cancelAndClose(){
        operation?.cancel()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if(pagesPerSheet == "1"){
            needToFormatPDF = false
        }
        
        filename = filePath.lastPathComponent
        filePathString = filePath.path
        
        if(isFileAPdf(filename)){
            needToConvertDocToPDF = false
        }
        
        if(startPageRange > 0){
            needToTrimPDFToPageRange = true
        }
        
        
        progressTable.delegate = self
        progressTable.dataSource = self
        
        
        startPrinting()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = TAG;
    }
    
    
    func isFileAPdf(filename : String) -> Bool{
        let filenameNS : NSString = filename as NSString
        
        let fileType : String = filenameNS.pathExtension
        
        
        if fileType.rangeOfString("pdf") == nil {
            return false
        } else {
            return true
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row : Int = indexPath.row
        
        if(row == POSITION_UPLOADING_DOC_CONVERTER && !needToConvertDocToPDF
            || row == POSITION_CONVERTING_TO_PDF && !needToConvertDocToPDF
            || row == POSITION_UPLOADING_PDF_CONVERTER && !needToFormatPDF
            || row == POSITION_FORMATTING_PDF && !needToFormatPDF
            || row == POSITION_TRIM_PDF_TO_PAGE_RANGE && !needToTrimPDFToPageRange){
                return CELL_ROW_ZERO_HEIGHT
        }  else {
            return CELL_ROW_HEIGHT
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HEADER_TEXT.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell : PrintingViewTableCell? = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as? PrintingViewTableCell
        
        
        if (cell == nil) {
            cell = PrintingViewTableCell(style: UITableViewCellStyle.Default, reuseIdentifier: CELL_IDENTIFIER)
        }
        
        
        processCell(cell!, row: indexPath.row)
        
        return cell!;
    }
    
    
    func processCell(cell : PrintingViewTableCell, row : Int){
        
        cell.clipsToBounds = true
        
        if(row == POSITION_UPLOADING_USER_DOC){
            cell.header.text = String(format:HEADER_TEXT[row], filename)
        } else if(row == POSITION_FORMATTING_PDF){
            cell.header.text = String(format:HEADER_TEXT[row], pagesPerSheet)
        } else if(row == POSITION_SENDING_TO_PRINTER){
            cell.header.text = String(format:HEADER_TEXT[row], printer)
        } else if(row == POSITION_TRIM_PDF_TO_PAGE_RANGE){
            cell.header.text = String(format:HEADER_TEXT[row], startPageRange, endPageRange)
        } else {
            cell.header.text = HEADER_TEXT[row]
        }
        
        
        cell.progressBar.hidden = PROGRESS_INDETERMINATE[row]
        
        
        //Adjust Tick
        if(currentProgress > row){
            cell.tick.hidden = false
        } else {
            cell.tick.hidden = true
        }
        
        
        if(row == currentProgress){
            if(operation == nil){
                //Means the operation has ended on the current progress, show a cross to mean an error
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.hidden = true
                cell.cross.hidden = false
            } else if(!cell.activityIndicator.isAnimating()){
                cell.activityIndicator.hidden = false
                cell.activityIndicator.startAnimating()
            }
        } else {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidden = true
        }
        
        if(row == POSITION_UPLOADING_DOC_CONVERTER){
            
            let progress = generateProgressStringAndProgressFraction(docConvUploaded, totalSize: docConvSize)
            
            cell.smallFooter.text = progress.progressString
            cell.progressBar.progress = progress.progressFraction
            
        }
        
        
        if(row == POSITION_UPLOADING_PDF_CONVERTER){
            
            let progress = generateProgressStringAndProgressFraction(pdfConvUploaded, totalSize: pdfConvSize)
            
            cell.smallFooter.text = progress.progressString
            cell.progressBar.progress = progress.progressFraction
            
        }
        
        
        if(row == POSITION_UPLOADING_USER_DOC){
            let progress = generateProgressStringAndProgressFraction(docToPrintUploaded, totalSize: docToPrintSize)
            
            cell.smallFooter.text = progress.progressString
            cell.progressBar.progress = progress.progressFraction
        }
        
        
        if(row == POSITION_CONVERTING_TO_PDF || row == POSITION_TRIM_PDF_TO_PAGE_RANGE || row == POSITION_CONVERTING_TO_POSTSCRIPT){
            cell.smallFooter.text = TEXT_INDETERMINATE
        }
        
        
        
        
    }
    
    
    
    func generateProgressStringAndProgressFraction(currentSize : Int, totalSize : Int) -> (progressString : String, progressFraction : Float){
        let doubleCurrent = Double(currentSize)
        let doubleTotal = Double(totalSize)
        
        var progressFraction : Float = 0
        
        if(totalSize != 0){
            progressFraction = Float(doubleCurrent / doubleTotal)
        }
        
        let percent = progressFraction * 100
        
        let byteCountFormatter = NSByteCountFormatter()
        byteCountFormatter.zeroPadsFractionDigits = true
        byteCountFormatter.countStyle = NSByteCountFormatterCountStyle.File
        
        
        let uploadedStr = byteCountFormatter.stringFromByteCount(Int64(currentSize))
        
        let totalStr = byteCountFormatter.stringFromByteCount(Int64(totalSize))
        
        let formatString = String(format: FORMAT_UPLOADING, uploadedStr, totalStr, percent)
        
        return (formatString, progressFraction)
        
        
    }
    
    
    func startPrinting(){
        
        if(operation != nil){
            return
        }
        
        let preferences : Storage = Storage.sharedInstance;
        
        
        let username : String?  = preferences.getUsername()
        let password : String? = preferences.getPassword()
        let hostname : String = preferences.getServer()
        
        
        if(username == nil || username!.isEmpty || password == nil || password!.isEmpty){
            showAlert(TITLE_STOP, message: FULL_CREDENTIALS_NOT_SET, viewController: self)
        } else {
            
            currentProgress = 0
            
            operation = PrintingOperation(hostname: hostname, username: username!, password: password!, filePath : filePathString, pagesPerSheet : pagesPerSheet, startPage : startPageRange, endPage : endPageRange, printerName : printer, parent : self)
            
            operation!.completionBlock = {(void) in
                self.operation = nil
                
                dispatch_async(dispatch_get_main_queue(), {(void) in
                    self.cancelButton.setTitle(self.CLOSE_TEXT, forState: UIControlState.Normal)
                })
                
            }
            
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {(void) in
                self.operation!.start()
            })
            
            
            
        }
        
        
    }
    
    
    //Override this, 1 for yes, 0 for no
    override func receiveAlertViewResponse(alertTag : Int, clickedButtonIndex : Int){
        NSLog("%@ alertview clicked %d", TAG, clickedButtonIndex)
        
        if(alertTag == ALERT_CANCEL_OPERATION_TAG){
            if(clickedButtonIndex == 1){
                cancelCurrentOperation()
            }
        } else if(alertTag == ALERT_CONTINUE_DOC_UPLOAD_TAG){
            if(clickedButtonIndex == 1){ //Yes button
                self.continueWithDocumentUpload = true
            } else if(clickedButtonIndex == 0){ //No button
                self.continueWithDocumentUpload = false
            }
            
            self.unlockSemaphore()
        }
    }
    
    
    
    
    func showUploadDocConverterChoiceAlert(title: String, message : String){
        showYesNoAlert(title, message: message, viewController: self, alertTag: ALERT_CONTINUE_DOC_UPLOAD_TAG)
    }
    

    
    func showCancelOperationAlert(title: String, message : String, viewController : UIViewController){
        showYesNoAlert(title, message: message, viewController: self, alertTag: ALERT_CANCEL_OPERATION_TAG)
    }
    

    
    func cancelCurrentOperation(){
        NSLog("%@ Cancel current operation", TAG)
        cancelAndClose()
    }
    
    
    func unlockSemaphore(){
        
        NSLog("%@ unlockSemaphore", TAG);
        
        if(semaphore != nil){
            dispatch_semaphore_signal(semaphore!);
            semaphore = nil;
        }
    }
    
    
    
    
}
class PrintingOperation : NSOperation {
    
    
    let PDF_CONVERTER_NAME = "nup_pdf"
    let PDF_CONVERTER_FILENAME = "nup_pdf.jar"
    let PDF_CONVERTER_FILEPATH = "socPrint/nup_pdf.jar"
    
    //This converter is for 6 pages/sheet as nup_pdf cannot generate such a file
    let PDF_CONVERTER_6PAGE_NAME = "Multivalent"
    let PDF_CONVERTER_6PAGE_FILENAME = "Multivalent.jar"
    let PDF_CONVERTER_6PAGE_FILEPATH = "socPrint/Multivalent.jar"
    
    let DOC_CONVERTER_NAME = "docs-to-pdf-converter-1.7"
    let DOC_CONVERTER_FILENAME = "docs-to-pdf-converter-1.7.jar"
    let DOC_CONVERTER_FILEPATH = "socPrint/docs-to-pdf-converter-1.7.jar"
    
    let PDF_CONVERTER_MD5 = "C1F8FF3F9DE7B2D2A2B41FBC0085888B"
    let PDF_CONVERTER_6PAGE_MD5 = "813BB651A1CC6EA230F28AAC47F78051"
    let DOC_CONVERTER_MD5 = "1FC140AD8074E333F9082300F4EA38DC"
    
    let TEMP_DIRECTORY = "socPrint/"
    
    let UPLOAD_FILEPATH = "socPrint/source." //Add path extension later
    let UPLOAD_SOURCE_PDF_FILEPATH = "socPrint/source.pdf"
    let UPLOAD_PDF_TRIMMED_FILEPATH = "socPrint/source-trimmed.pdf"
    let UPLOAD_PDF_FORMATTED_TRIMMED_6PAGE_FILEPATH = "socPrint/source-trimmed-up.pdf"
    let UPLOAD_PDF_FORMATTED_6PAGE_FILEPATH = "socPrint/source-up.pdf"
    let UPLOAD_PDF_FORMATTED_FILEPATH = "socPrint/formatted.pdf"
    let UPLOAD_PS_FILEPATH_FORMAT = "socPrint/\"%@.ps\""
    
    let DIALOG_UPLOAD_DOC_CONV_FAILED = "Upload of document converter failed"
    let DIALOG_UPLOAD_PDF_FORMATTER_FAILED = "Upload of PDF formatter failed"
    let DIALOG_UPLOAD_DOCUMENT_FAILED = "Upload of your document failed"
    let DIALOG_CONVERT_TO_PDF_FAILED = "Converting your document to PDF failed"
    let DIALOG_TRIM_PDF_FAILED = "Trim PDF to page %d to %d failed"
    let DIALOG_CONVERT_TO_PS_FAILED = "Conversion to Postscript failed"
    let DIALOG_PRINT_COMMAND_ERROR = "Printing command error"
    
    let DIALOG_ASK_UPLOAD_DOC_TITLE = "Upload DOC converter?"
    let DIALOG_ASK_UPLOAD_DOC_MESSAGE = "Using the document converter requires a 47MB upload. You seem to be on mobile data so uploading this could be expensive.\n\nDo you want to continue?"
    
    let DIALOG_ASK_UPLOAD_DOC_YES = "Yes"
    let DIALOG_ASK_UPLOAD_DOC_NO = "No"
    
    
    var connection : SSHConnectivity!
    var username : String!
    var password : String!
    var hostname : String!
    var pagesPerSheet : String!
    var printerName : String!
    var startPage : Int
    var endPage : Int
    var parent : PrintingViewController!
    var givenFilePath : String!
    var uploadedFilepath : String!
    
    
    
    init(hostname : String, username : String, password : String, filePath : String, pagesPerSheet : String, startPage : Int, endPage : Int, printerName : String, parent : PrintingViewController) {
        self.username = username
        self.password = password
        self.hostname = hostname
        self.givenFilePath = filePath
        self.pagesPerSheet = pagesPerSheet
        self.printerName = printerName
        self.startPage = startPage
        self.endPage = endPage
        let fileExtension : String = (givenFilePath as NSString).pathExtension
        uploadedFilepath = UPLOAD_FILEPATH + fileExtension
        self.parent = parent
        
    }
    
    override func main() {
        
        //Step -1: Tell Google Analytics printing actions
        let fileType : String = (givenFilePath as NSString).pathExtension
        
        let tracker = GAI.sharedInstance().defaultTracker
        
        let dictPrinterName : NSMutableDictionary = GAIDictionaryBuilder.createEventWithCategory("printing", action: "printer", label: printerName, value: nil).build()
        let dictPagesPerSheet : NSMutableDictionary =  GAIDictionaryBuilder.createEventWithCategory("printing", action: "pagesPerSheet", label: pagesPerSheet, value: nil).build()
        let dictFileType : NSMutableDictionary =  GAIDictionaryBuilder.createEventWithCategory("printing", action: "fileType", label: fileType, value: nil).build()
        
        if(parent.needToTrimPDFToPageRange){
            let dictStartPage =  GAIDictionaryBuilder.createEventWithCategory("printing", action: "startPage", label: String(startPage), value: nil).build()
            
            let dictEndPage : NSMutableDictionary =  GAIDictionaryBuilder.createEventWithCategory("printing", action: "endPage", label: String(endPage), value: nil).build()

            //This part has to be check to see if it works
            tracker.send(dictStartPage as [NSObject : AnyObject])
            tracker.send(dictEndPage as [NSObject : AnyObject])
        }
        
        //This part has to be check to see if it works
        tracker.send(dictPrinterName as [NSObject : AnyObject])
        tracker.send(dictPagesPerSheet as [NSObject : AnyObject])
        tracker.send(dictFileType as [NSObject : AnyObject])
        
        
        
        
        //Step 0: Connecting to server
        parent.currentProgress = parent.POSITION_CONNECTING
        updateUI()
        
        connection = SSHConnectivity(hostname: hostname!, username: username!, password: password!)
        let connectionStatus = connection.connect()
        
        let serverFound : Bool = connectionStatus.serverFound
        let authorised : Bool = connectionStatus.authorised
        
        if(serverFound){
            if(!authorised){
                stepFailAndCleanUpOperation(CREDENTIALS_WRONG)
                return
            }
        } else {
            stepFailAndCleanUpOperation(SERVER_UNREACHABLE)
            return
        }
        
        //Step 1: Housekeeping, creating socPrint folder if not yet, delete all files except converters
        
        if(!cancelled){
            parent.currentProgress = parent.POSITION_HOUSEKEEPING
            updateUI()
            
            connection.createDirectory(TEMP_DIRECTORY)
            
            let houseKeepingCommand = "find " + TEMP_DIRECTORY + " -type f \\( \\! -name '" + PDF_CONVERTER_FILENAME + "' \\) \\( \\! -name '" + DOC_CONVERTER_FILENAME + "' \\) \\( \\! -name '" + PDF_CONVERTER_6PAGE_FILENAME + "' \\) -exec rm '{}' \\;"
            
            connection.runCommand(houseKeepingCommand)
        }
        
        
        //Step 2 : Uploading DOC converter
        if(parent.needToConvertDocToPDF && !cancelled){
            parent.currentProgress = parent.POSITION_UPLOADING_DOC_CONVERTER
            updateUI()
            
            let needToUpload = doesThisFileNeedToBeUploaded(DOC_CONVERTER_FILEPATH, md5Value: DOC_CONVERTER_MD5)
            
            
            let pathToDocConverter : String = NSBundle.mainBundle().pathForResource(DOC_CONVERTER_NAME, ofType: "jar")!
            let docConvSize : Int = getFileSizeOfFile(pathToDocConverter)
            
            if(needToUpload){
                
                let isOn3G = ConstantsObjC.isOn3G()
                
                if(isOn3G){
                    parent.semaphore = dispatch_semaphore_create(0);
                    askWhetherToUploadDocConverter()
                    dispatch_semaphore_wait(parent.semaphore!, DISPATCH_TIME_FOREVER);
                    
                    if(!parent.continueWithDocumentUpload){
                        cleanUpOperation()
                        return
                    }
                    
                }
                

            
                let docConvUploadProgressBlock = {(bytesUploaded : UInt) -> Bool in
                    
                    let bytesUploadedInt : Int = Int(bytesUploaded)
                    
                    self.updateUIDocConvUpload(docConvSize, uploadedSize: bytesUploadedInt)
                    if(self.cancelled){
                        return false
                    } else {
                        return true
                    }
                }
                
                let uploadStatus = connection.uploadFile(pathToDocConverter, destinationPath: DOC_CONVERTER_FILEPATH, progress: docConvUploadProgressBlock)
                
                if(!uploadStatus){
                    stepFailAndCleanUpOperation(DIALOG_UPLOAD_DOC_CONV_FAILED)
                    return
                }
                
            } else {
                
                //Already exists, just use existing file
                self.updateUIDocConvUpload(docConvSize, uploadedSize: docConvSize)
            }
            
        }
        
        
        //Step 3 : Uploading PDF converter
        if(parent.needToFormatPDF && !cancelled){
            parent.currentProgress = parent.POSITION_UPLOADING_PDF_CONVERTER
            updateUI()
            
            
            
            var actualFilePath : String!
            var actualMD5 : String!
            var actualName : String!
            
            
            
            if(pagesPerSheet == "6"){
                actualFilePath = PDF_CONVERTER_6PAGE_FILEPATH
                actualMD5 = PDF_CONVERTER_6PAGE_MD5
                actualName = PDF_CONVERTER_6PAGE_NAME
            } else {
                actualFilePath = PDF_CONVERTER_FILEPATH
                actualMD5 = PDF_CONVERTER_MD5
                actualName = PDF_CONVERTER_NAME
            }
            
            
            let needToUpload = doesThisFileNeedToBeUploaded(actualFilePath, md5Value: actualMD5)
            
            
            let pathToPdfConverter : String = NSBundle.mainBundle().pathForResource(actualName, ofType: "jar")!
            let pdfConvSize : Int = getFileSizeOfFile(pathToPdfConverter)
            
            if(needToUpload){
                let pdfConvUploadProgressBlock = {(bytesUploaded : UInt) -> Bool in
                    
                    let bytesUploadedInt : Int = Int(bytesUploaded)
                    
                    self.updateUIPDFConvUpload(pdfConvSize, uploadedSize: bytesUploadedInt)
                    if(self.cancelled){
                        return false
                    } else {
                        return true
                    }
                }
                
                let uploadStatus = connection.uploadFile(pathToPdfConverter, destinationPath: actualFilePath, progress: pdfConvUploadProgressBlock)
                
                if(!uploadStatus){
                    stepFailAndCleanUpOperation(DIALOG_UPLOAD_PDF_FORMATTER_FAILED)
                    return
                }
                
            } else {
                
                //Already exists, just use existing file
                self.updateUIPDFConvUpload(pdfConvSize, uploadedSize: pdfConvSize)
            }
            
        }
        
        //Step 4 : Uploading document
        
        if(!cancelled){
            parent.currentProgress = parent.POSITION_UPLOADING_USER_DOC
            updateUI()
            
            let documentSize : Int = getFileSizeOfFile(givenFilePath)
            
            
            let documentUploadProgressBlock = {(bytesUploaded : UInt) -> Bool in
                
                let bytesUploadedInt : Int = Int(bytesUploaded)
                
                self.updateUIDocToPrintUpload(documentSize, uploadedSize: bytesUploadedInt)
                if(self.cancelled){
                    return false
                } else {
                    return true
                }
            }
            
            let uploadStatus = connection.uploadFile(givenFilePath, destinationPath: uploadedFilepath, progress: documentUploadProgressBlock)
            
            
            if(!uploadStatus){
                stepFailAndCleanUpOperation(DIALOG_UPLOAD_DOCUMENT_FAILED)
                return
            }
            
        }
        
        //Step 5 : Convert document to PDF if necessary
        if(parent.needToConvertDocToPDF && !cancelled){
            parent.currentProgress = parent.POSITION_CONVERTING_TO_PDF
            updateUI()
            
            
            let conversionCommand : String = "java -jar " + DOC_CONVERTER_FILEPATH + " -i " + uploadedFilepath + " -o " + UPLOAD_SOURCE_PDF_FILEPATH;
            
            let reply : String = connection.runCommand(conversionCommand)
            
            if(reply.utf16.count != 0){
                stepFailAndCleanUpOperation(DIALOG_CONVERT_TO_PDF_FAILED, messageToShow : reply)
                return
            }
            
            
        }
        
        var pdfFilepathToFormat : String!
        
        //Step 6: Trim PDF to page range if necessary
        if(!cancelled){
            if(parent.needToTrimPDFToPageRange){
                parent.currentProgress = parent.POSITION_TRIM_PDF_TO_PAGE_RANGE
                updateUI()
                
                let startNumberString = String(startPage)
                let endNumberString = String(endPage)
                
                let trimCommand = "gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dFirstPage=" + startNumberString + " -dLastPage=" + endNumberString + " -sOutputFile=" + UPLOAD_PDF_TRIMMED_FILEPATH + " " + UPLOAD_SOURCE_PDF_FILEPATH
                
                let reply : String = connection.runCommand(trimCommand)
                
                let range : Range<String.Index>? = reply.rangeOfString("Requested FirstPage is greater than the number of pages in the file")
                
                if(range != nil){
                    let failedTrimTitle = String(format: DIALOG_TRIM_PDF_FAILED, arguments: [startPage, endPage])
                    
                    let startIndex = range!.startIndex
                    let endIndex = reply.endIndex
                    
                    let errorMsg = reply.substringWithRange(Range<String.Index>(start: startIndex, end: endIndex))
                    
                    stepFailAndCleanUpOperation(failedTrimTitle, messageToShow: errorMsg)
                    return
                }
        
                
                pdfFilepathToFormat = UPLOAD_PDF_TRIMMED_FILEPATH
                
            } else {
                pdfFilepathToFormat = UPLOAD_SOURCE_PDF_FILEPATH
            }
        }
        
        
        
        //Step 7 : Format PDF to required pages per sheet if required
        var pdfFilepathToConvertToPS : String!
        
        if(!cancelled){
            
            if(parent.needToFormatPDF){
                parent.currentProgress = parent.POSITION_FORMATTING_PDF
                updateUI()
                
                var formattingCommand : String!;
                if(pagesPerSheet == "6"){
                    formattingCommand = "java -classpath " + PDF_CONVERTER_6PAGE_FILEPATH + " tool.pdf.Impose -paper a4 -nup 6 " + pdfFilepathToFormat;
                    
                    if(parent.needToTrimPDFToPageRange){
                        pdfFilepathToConvertToPS = UPLOAD_PDF_FORMATTED_TRIMMED_6PAGE_FILEPATH
                    } else {
                        pdfFilepathToConvertToPS = UPLOAD_PDF_FORMATTED_6PAGE_FILEPATH
                    }

                } else {
                    formattingCommand = "java -jar " + PDF_CONVERTER_FILEPATH + " " + pdfFilepathToFormat + " " + UPLOAD_PDF_FORMATTED_FILEPATH + " " + pagesPerSheet
                    pdfFilepathToConvertToPS = UPLOAD_PDF_FORMATTED_FILEPATH
                }
                
                connection.runCommand(formattingCommand)
                
                
            } else {
                
                if(parent.needToTrimPDFToPageRange){
                    pdfFilepathToConvertToPS = UPLOAD_PDF_TRIMMED_FILEPATH
                } else {
                    pdfFilepathToConvertToPS = UPLOAD_SOURCE_PDF_FILEPATH
                }
            }
            
        }
        let psFileNameNoString = ((givenFilePath as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
        
        let psFilePath = String(format: UPLOAD_PS_FILEPATH_FORMAT, psFileNameNoString)
        
        //Step 8 : Converting to Postscript
        if(!cancelled){
            parent.currentProgress = parent.POSITION_CONVERTING_TO_POSTSCRIPT
            updateUI()
            
            let conversionCommand : String = "pdftops " + pdfFilepathToConvertToPS + " " + psFilePath
            let reply = connection.runCommand(conversionCommand)
            
            if(reply.utf16.count != 0){
                stepFailAndCleanUpOperation(DIALOG_CONVERT_TO_PS_FAILED, messageToShow: reply)
                return
            }
        }
        
        
        //Final Step 9 : Send to printer!!!
        
        if(!cancelled){
            parent.currentProgress = parent.POSITION_SENDING_TO_PRINTER
            updateUI()
            
            let printingCommand : String = "lpr -P " + printerName + " " + psFilePath
            let output = connection.runCommand(printingCommand)
            if(output.utf16.count != 0){
                stepFailAndCleanUpOperation(DIALOG_PRINT_COMMAND_ERROR, messageToShow: output)
                return
            }
            
        }
        
        parent.currentProgress = parent.POSITION_COMPLETED
        updateUI()
        
        
        
        
        self.connection.disconnect()
        self.connection = nil
        
        
    }
    
    func stepFailAndCleanUpOperation(messageToShow : String){
        stepFailAndCleanUpOperation(TITLE_STOP, messageToShow: messageToShow)
    }
    
    
    func stepFailAndCleanUpOperation(title : String, messageToShow : String){
        showAlertInUIThread(title, message: messageToShow, viewController: parent)
        cleanUpOperation()
    }
    
    func cleanUpOperation(){
        self.connection.disconnect()
        self.connection = nil
        
        dispatch_async(dispatch_get_main_queue(), {(void) in
            self.parent.progressTable.reloadData()
        })
    }
    
    func doesThisFileNeedToBeUploaded(filepath : String, md5Value : String) -> Bool{
        let command = "md5 " + filepath
        let commandOutput = self.connection.runCommand(command)
        
        if(commandOutput.hasPrefix(md5Value)){
            return false
        } else {
            return true
        }
        
    }
    
    func updateUIDocToPrintUpload(totalSize : Int, uploadedSize : Int){
        
        dispatch_async(dispatch_get_main_queue(), {(void) in
            
            self.parent.docToPrintSize = totalSize
            self.parent.docToPrintUploaded = uploadedSize
            self.parent.progressTable.reloadData()
            
        })
    }
    
    
    func updateUIPDFConvUpload(totalSize : Int, uploadedSize : Int){
        
        dispatch_async(dispatch_get_main_queue(), {(void) in
            
            self.parent.pdfConvSize = totalSize
            self.parent.pdfConvUploaded = uploadedSize
            self.parent.progressTable.reloadData()
            
        })
    }
    
    func updateUIDocConvUpload(totalSize : Int, uploadedSize : Int){
        
        dispatch_async(dispatch_get_main_queue(), {(void) in
            
            self.parent.docConvSize = totalSize
            self.parent.docConvUploaded = uploadedSize
            self.parent.progressTable.reloadData()
            
        })
    }
    
    
    func askWhetherToUploadDocConverter(){
        dispatch_async(dispatch_get_main_queue(), {(void) in
            self.parent.showUploadDocConverterChoiceAlert(self.DIALOG_ASK_UPLOAD_DOC_TITLE, message: self.DIALOG_ASK_UPLOAD_DOC_MESSAGE)
            
        })
        
    }
    
    
    func getFileSizeOfFile(path : String) -> Int {
        
        do {
            let attributes : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
            
            if(attributes != nil){
                let size : Int = attributes!.objectForKey(NSFileSize)!.longValue
                return size
            } else {
                return 0
            }

        } catch {
            return 0
        }
    }
    
    
    func updateUI(){
        dispatch_async(dispatch_get_main_queue(), {(void) in
            self.parent.progressTable.reloadData()
        })
    }
    
    
    
}


