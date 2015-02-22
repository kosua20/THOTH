//
//  Renderer.swift
//  Siblog
//
//  Created by Simon Rodriguez on 27/01/2015.
//  Copyright (c) 2015 Simon Rodriguez. All rights reserved.
//

import Foundation
//TODO: générer sitemap.xml et feed.xml

class Renderer {
    let articlesToRender : [Article]
    let exportPath: String
    let templatePath : String
    let resourcesPath : String
    let articlesPath : String
    let blogTitle : String
    var articleHtml : NSString = ""
    var indexHtml : NSString = ""
    var snippetHtml : NSString = ""
    var headerHtml : NSString = ""
    var footerHtml : NSString = ""
    var insertIndex = 0
    var markdown : Markdown
    //var forceUpdate : Bool = false
    
    init(articles: [Article], articlesPath : String, exportPath : String, rootPath : String, templatePath: String, defaultWidth : String, blogTitle : String, imagesLink : Bool){
        self.exportPath = exportPath
        self.articlesPath = articlesPath
        self.templatePath = templatePath
        self.resourcesPath = rootPath.stringByAppendingPathComponent("resources")
        self.articlesToRender = articles
        self.blogTitle = blogTitle
        var options = MarkdownOptions()
        options.defaultWidth = defaultWidth
        options.imagesAsLinks = imagesLink
        markdown = Markdown(options: options)
        if !NSFileManager.defaultManager().fileExistsAtPath(exportPath) {
            NSFileManager.defaultManager().createDirectoryAtPath(exportPath, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
        initializeTemplate()
        loadTemplate()
    }
    
    func updateIndex(){
        renderIndex()
        copyResources(false)
    }
    
    func defaultExport(){
        renderArticles(false)
        renderDrafts(true)
        renderIndex()
        renderDraftIndex()
        copyResources(false)
    }
    
    func articlesOnly(){
        renderArticles(true)
        renderIndex()
        copyResources(false)
    }
    
    func articlesForceOnly() {
        renderArticles(true)
        renderDrafts(false)
        renderIndex()
        renderDraftIndex()
        copyResources(false)
    }
    
    func draftsOnly(){
        renderDrafts(true)
        renderDraftIndex()
        copyResources(false)
    }
    
    func draftsForceOnly() {
        renderDrafts(true)
        renderArticles(false)
        renderDraftIndex()
        renderIndex()
        copyResources(false)
    }
    
    func fullExport() {
        clean()
        restoreTemplate()
        renderArticles(true)
        renderDrafts(true)
        renderIndex()
        renderDraftIndex()
        copyResources(true)
    }
    
    func updateResources(){
        copyResources(true)
    }
    
    func clean(){
        if NSFileManager.defaultManager().fileExistsAtPath(exportPath) {
            NSFileManager.defaultManager().removeItemAtPath(exportPath, error: nil)
        }
        NSFileManager.defaultManager().createDirectoryAtPath(exportPath, withIntermediateDirectories: true, attributes: nil, error: nil)
        NSFileManager.defaultManager().createDirectoryAtPath(exportPath.stringByAppendingPathComponent("articles"), withIntermediateDirectories: true, attributes: nil, error: nil)
        NSFileManager.defaultManager().createDirectoryAtPath(exportPath.stringByAppendingPathComponent("drafts"), withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    func cleanFolder(folder : String) {
        let folderPath = exportPath.stringByAppendingPathComponent(folder)
        if NSFileManager.defaultManager().fileExistsAtPath(folderPath) {
            NSFileManager.defaultManager().removeItemAtPath(folderPath, error: nil)
        }
        NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    func copyResources(forceUpdate : Bool){
        if NSFileManager.defaultManager().fileExistsAtPath(resourcesPath) {
            let exportResourcesPath = exportPath.stringByAppendingPathComponent("resources")
            if !NSFileManager.defaultManager().fileExistsAtPath(exportResourcesPath) {
                NSFileManager.defaultManager().createDirectoryAtPath(exportResourcesPath, withIntermediateDirectories: true, attributes: nil, error: nil)
            }
            let paths = NSFileManager.defaultManager().contentsOfDirectoryAtPath(resourcesPath, error: nil) as [NSString]
            for path in paths {
                if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(exportResourcesPath.stringByAppendingPathComponent(path)){
                    NSFileManager.defaultManager().copyItemAtPath(resourcesPath.stringByAppendingPathComponent(path), toPath: exportResourcesPath.stringByAppendingPathComponent(path), error: nil)
                }
            }
        }
        
    }
        
    func initializeTemplate(){
        let templateFiles = NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatePath, error: nil) as [String]
        for path in templateFiles{
            if !NSFileManager.defaultManager().fileExistsAtPath(exportPath.stringByAppendingPathComponent(path.lastPathComponent)){
                NSFileManager.defaultManager().copyItemAtPath(templatePath.stringByAppendingPathComponent(path), toPath: exportPath.stringByAppendingPathComponent(path.lastPathComponent), error: nil)
            }
        }
        //NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("index.html"), error: nil)
        NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("article.html"), error: nil)
    }
        
    func restoreTemplate(){
        let templateFiles = NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatePath, error: nil) as [String]
        for path in templateFiles{
            NSFileManager.defaultManager().copyItemAtPath(templatePath.stringByAppendingPathComponent(path), toPath: exportPath.stringByAppendingPathComponent(path.lastPathComponent), error: nil)
        }
        NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("index.html"), error: nil)
        NSFileManager.defaultManager().removeItemAtPath(exportPath.stringByAppendingPathComponent("article.html"), error: nil)
    }
    
    func loadTemplate(){
       if let data: NSData = NSFileManager.defaultManager().contentsAtPath(templatePath.stringByAppendingPathComponent("article.html")) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                articleHtml = str
            } else {
                 println("error")
            }
        } else {
            println("error")
        }
        
        if let data: NSData = NSFileManager.defaultManager().contentsAtPath(templatePath.stringByAppendingPathComponent("index.html")) {
            if let str = NSString(data: data, encoding : NSUTF8StringEncoding) {
                indexHtml = str
            } else {
                println("error")
            }
        } else {
            println("error")
        }
        
        if indexHtml.length > 0 {
            snippetHtml = extractSnippetHtml(indexHtml)
            if snippetHtml.length == 0 {
                println("error")
                return
            }
            headerHtml = indexHtml.substringToIndex(insertIndex)
            //println("\(snippetHtml.length),\(insertIndex)")
            footerHtml = indexHtml.substringFromIndex(insertIndex + 30 + snippetHtml.length)
        }
    }
    
    func extractSnippetHtml(code : NSString)-> NSString{
        let scanner = NSScanner(string:  code)
        var res : NSString?
        scanner.scanUpToString("{#ARTICLE_BEGIN}", intoString: nil)
        insertIndex = scanner.scanLocation
        scanner.scanUpToString("{#ARTICLE_END}", intoString: &res)
        if let str2 : NSString = res?.substringFromIndex(16) {
            return str2
        }
        return ""
    }
    
    func renderArticles(forceUpdate : Bool){
        if forceUpdate {
            cleanFolder("articles")
        }
        for article in articlesToRender {
            if !article.isDraft {
                renderArticle(article, inFolder: "articles", forceUpdate : forceUpdate)
            }
        }
    }
    
    func renderDrafts(forceUpdate : Bool){
        if forceUpdate {
            cleanFolder("drafts")
        }
        for article in articlesToRender {
            if article.isDraft {
                renderArticle(article, inFolder: "drafts", forceUpdate : forceUpdate)
            }
        }
    }
    
    
    //, var withRenderer markdown : Markdown)
    func renderArticle(article : Article, inFolder folder : String, forceUpdate : Bool){
        let filePath = exportPath.stringByAppendingPathComponent(folder).stringByAppendingPathComponent(article.getUrlPathname())
        if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(filePath){
            var html: NSString = articleHtml.copy() as NSString
            html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
            html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
            html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
            html = html.stringByReplacingOccurrencesOfString("{#BLOGTITLE}", withString: blogTitle)
            var contentHtml = markdown.transform(article.content)
            contentHtml = addFootnotes(contentHtml)
            contentHtml = manageImages(contentHtml,links: markdown.imagesUrl, path: filePath, forceUpdate : forceUpdate)
            html = html.stringByReplacingOccurrencesOfString("{#CONTENT}", withString: contentHtml)
            NSFileManager.defaultManager().createFileAtPath(filePath, contents: html.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
        }
    }
    
    func manageImages(var content : String, links : [String], path filePath : String, forceUpdate : Bool) -> String {
        if links.count > 0 {
            if !NSFileManager.defaultManager().fileExistsAtPath(filePath.stringByDeletingPathExtension) {
                NSFileManager.defaultManager().createDirectoryAtPath(filePath.stringByDeletingPathExtension, withIntermediateDirectories: true, attributes: nil, error: nil)
            }
            for link in links {
                if !link.hasPrefix("http://") && !link.hasPrefix("www.") {
                //We are now sure the file is stored locally
                    var path = expandLink(link)
                    if NSFileManager.defaultManager().fileExistsAtPath(path) {
                        let newFilePath = filePath.stringByDeletingPathExtension.stringByAppendingPathComponent(path.lastPathComponent)
                        if forceUpdate || !NSFileManager.defaultManager().fileExistsAtPath(newFilePath) {
                            NSFileManager.defaultManager().copyItemAtPath(path, toPath: newFilePath, error: nil)
                            content = content.stringByReplacingOccurrencesOfString(link, withString: filePath.lastPathComponent.stringByDeletingPathExtension.stringByAppendingPathComponent(path.lastPathComponent), options: nil, range: nil)
                        }
                    } else {
                        println("Warning: some images were not found")
                    }
                }
            }
        }
        return content
    }
    
    func expandLink(var link : String) -> String {
        if link.hasPrefix("/") {
            //Absolute path
            return link
        } else {
            //Relative path
            //Apparemment NSFileManager gère ça tout seul, à tester avec des images dans un dossier du dossier parent.
            return articlesPath.stringByAppendingPathComponent(link)
        }
    }
    
    func renderIndex() {
        indexHtml = footerHtml.copy() as NSString
        for article in articlesToRender {
            if !article.isDraft {
                var html : NSString = snippetHtml.copy() as NSString
                html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
                html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
                html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
                html = html.stringByReplacingOccurrencesOfString("{#LINK}", withString: "articles/"+article.getUrlPathname())
                let contentHtml0 : NSString = markdown.transform(article.getSummary())
                var contentHtml = contentHtml0.mutableCopy() as NSMutableString
                let regex1 = NSRegularExpression(pattern: "<[^>]+>", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
                regex1?.replaceMatchesInString(contentHtml, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, contentHtml.length), withTemplate: "")
                html = html.stringByReplacingOccurrencesOfString("{#SUMMARY}", withString: contentHtml)
                indexHtml = NSString(format: "%@\n%@", html,indexHtml)
            }
        }
        indexHtml = headerHtml.stringByAppendingString(indexHtml)
        indexHtml = indexHtml.stringByReplacingOccurrencesOfString("{#BLOGTITLE}", withString: blogTitle)
        NSFileManager.defaultManager().createFileAtPath(exportPath.stringByAppendingPathComponent("index.html"), contents: indexHtml.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
    }
    
    func renderDraftIndex() {
        indexHtml = footerHtml.copy() as NSString
        for article in articlesToRender {
            if article.isDraft {
                var html : NSString = snippetHtml.copy() as NSString
                html = html.stringByReplacingOccurrencesOfString("{#TITLE}", withString: article.title)
                html = html.stringByReplacingOccurrencesOfString("{#DATE}", withString: article.dateString)
                html = html.stringByReplacingOccurrencesOfString("{#AUTHOR}", withString: article.author)
                html = html.stringByReplacingOccurrencesOfString("{#LINK}", withString: "drafts/"+article.getUrlPathname())
                let contentHtml0 : NSString = markdown.transform(article.getSummary())
                var contentHtml = contentHtml0.mutableCopy() as NSMutableString
                let regex1 = NSRegularExpression(pattern: "<[^>]+>", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
                regex1?.replaceMatchesInString(contentHtml, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, contentHtml.length), withTemplate: "")
                html = html.stringByReplacingOccurrencesOfString("{#SUMMARY}", withString: contentHtml)
                indexHtml = NSString(format: "%@\n%@", html,indexHtml)
            }
        }
        indexHtml = headerHtml.stringByAppendingString(indexHtml)
        indexHtml = indexHtml.stringByReplacingOccurrencesOfString("{#BLOGTITLE}", withString: blogTitle.stringByAppendingString(" - Drafts"))
        NSFileManager.defaultManager().createFileAtPath(exportPath.stringByAppendingPathComponent("index-drafts.html"), contents: indexHtml.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
    }
    
    func addFootnotes(var content : String) -> String{
        //TODO: gérer les footnotes référencées
        var count = 1
        let scanner1 = NSScanner(string: content)
        var newContent = ""
        var tempContent : NSString?
        var endContent = "\n<br>\n<br>\n<hr><ol>\n"
        var footNote : NSString?
        scanner1.scanUpToString("[^", intoString: &tempContent)
        if scanner1.atEnd {
            if let tempContent = tempContent {
                newContent = newContent.stringByAppendingString(tempContent)
            }
        }
        var isFirst = true
        var loopUsed = false
        while !scanner1.atEnd {
            loopUsed = true
            if let tempContent = tempContent {
                if isFirst {
                    newContent = newContent.stringByAppendingString(tempContent)
                    isFirst = false
                } else {
                    newContent = newContent.stringByAppendingString(tempContent.substringFromIndex(1))
                }
            }
            let location = scanner1.scanLocation
            scanner1.scanUpToString("]", intoString: &footNote)
            if var footNote : NSString = footNote {
                footNote = footNote.substringFromIndex(2)
                newContent = newContent.stringByAppendingString("<sup id=\"ref\(count)\"><a class=\"footnote-link\" href=\"#fn\(count)\" title=\"\" rel=\"footnote\">[\(count)]</a></sup>")
                endContent = endContent + "<li id=\"fn\(count)\" class=\"footnote\"><p>\(footNote) <a class=\"footnote-link\" href=\"#ref\(count)\" title=\"Return to footnote in the text.\" >&#8617;</a></p></li>\n"
                count++
            }
            scanner1.scanUpToString("[^", intoString: &tempContent)
        }
        if loopUsed {
            if let tempContent = tempContent {
                newContent = newContent.stringByAppendingString(tempContent.substringFromIndex(1))
            }
        }
        endContent += "</ol>\n"
        newContent += endContent
        return newContent
    }
    
    
}