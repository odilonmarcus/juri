import AppKit
import Foundation

struct PDFExporter {
    static func export(text: String, to url: URL) throws {
        let pageWidth: CGFloat = 520
        let pageHeight: CGFloat = 800
        let frame = NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let textView = NSTextView(frame: frame)
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 24, height: 24)
        textView.font = NSFont.systemFont(ofSize: 11)
        textView.string = text

        let printOptions: [NSPrintInfo.AttributeKey: Any] = [
            NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL: url
        ]

        let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOptions)
        printInfo.orientation = NSPrintInfo.PaperOrientation.portrait
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 42
        printInfo.rightMargin = 42
        printInfo.horizontalPagination = NSPrintInfo.PaginationMode.fit
        printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic

        let operation: NSPrintOperation = NSPrintOperation(view: textView, printInfo: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false

        guard operation.run() else {
            throw NSError(
                domain: "PDFExporter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Nao foi possivel gerar o PDF."]
            )
        }
    }
}
