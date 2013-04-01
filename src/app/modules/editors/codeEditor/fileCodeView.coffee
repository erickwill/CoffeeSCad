define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  require 'match_high'
  require 'search'
  require 'dialog'
  require 'hint'
  require 'jsHint'
  require 'indent_fold'
  
  CoffeeScript = require 'CoffeeScript'
  require 'coffeelint'
  
  vent = require 'modules/core/messaging/appVent'
  codeEditor_template = require "text!./fileCode.tmpl"

  class FileCodeView extends Backbone.Marionette.ItemView
    template: codeEditor_template
    className: "tab-pane"
    ui:
      codeBlock : "#codeArea"
      infoFooter: "#infoFooter"
      
    constructor:(options)->
      super options
      @vent = vent
      @settings = options.settings
      @editor = null
      @_markers = []
     
      @model.on("change", @modelChanged)
      @model.on("saved", @modelSaved)
      @settings.on("change", @settingsChanged)
      
      @vent.on("file:closed", @onFileClosed)
      @vent.on("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.on("file:undoRequest", @undo)
      @vent.on("file:redoRequest", @redo)
      
      #hack to fix annoying resize bug
      @vent.on("codeMirror:refresh",@onRefreshRequested)
    
    onRefreshRequested:(newHeight)=>
      #elHeight
      @editor.refresh()
      @editor.setSize("100%",newHeight)#"100%")
      @editor.refresh()
    
    onFileSelected:(model)=>
      if model == @model
        @$el.addClass('active')
        @$el.removeClass('fade')
        #temporarhack, needed because of rendering issues forcing to re-render, but thus loosing undo history
        history = @editor.getHistory()
        @render()
        @editor.setHistory history
        #@editor.refresh()
        @updateUndoRedo()
        @_updateHints()
        @editor.focus()
        @editor.refresh()
      else
        @_clearMarkers()
        @$el.removeClass('active')
        @$el.addClass('fade')
    
    onFileClosed:(fileName)=>
      if fileName == @model.get("name")
        @close()
    
    onShow:()=>
      @$el.addClass('active')
      @$el.removeClass('fade')
        
    onClose:()=>
      console.log "closing code view"
      #cleanup all vent event
      @vent.off("file:closed", @onFileClosed)
      @vent.off("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.off("file:undoRequest", @undo)
      @vent.off("file:redoRequest", @redo)
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @editor.setValue(@model.get("content"))
      @vent.trigger("clearUndoRedo", @)
      @editor.clearHistory()
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "saved", @modelSaved)
      
    modelChanged: (model, value)=>
      @applyStyles()
      
    modelSaved: (model)=>  
      
    applyStyles:=>  
      @$el.find('[rel=tooltip]').tooltip({'placement': 'right'})
      
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "fontSize"
            $(".CodeMirror").css("font-size","#{val}em")
          when "startLine"
            @editor.setOption("firstLineNumber",val)
            @render()
          when "linting"
            @_updateHints()
    
    _clearMarkers:=>
      @_markers = []
      @editor.clearGutter("lintAndErrorsGutter")
    
    _processError:(errorMsg, errorLevel, errorLine)=>
      #displays errors/warnings generated by the code inside the adapted gutter, returns a marker
      markerDiv= document.createElement("span")
      markerDiv$ = $(markerDiv)
      escape=(s)-> (''+s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')#.replace('"',"'")
      
      if errorLevel == "warn"
        markerDiv$.addClass("CodeWarningMarker") 
        markerMarkup= "<a href='#' rel='tooltip' title=\"#{escape errorMsg}\"> <i class='icon-remove-sign'></i></a>"
      else if errorLevel == "error"
        markerDiv$.addClass("CodeErrorMarker")
        markerMarkup= "<a href='#' rel='tooltip' title=\"#{escape errorMsg}\"> <i class='icon-remove-sign'></i></a>"
      
      markerDiv$.html(markerMarkup)
      marker = @editor.setGutterMarker(errorLine,"lintAndErrorsGutter",  markerDiv)
      return marker
    
    _updateHints:=>
      @_clearMarkers()
      try
        errors = coffeelint.lint(@editor.getValue(), @settings.get("linting"))
        if errors.length == 0
          @vent.trigger("file:noError")
        else
          @vent.trigger("file:errors",errors)
        for i, error of errors
          errorMsg = error.message
          errorLine = error.lineNumber-1
          errorLevel = error.level
          if not isNaN(errorLine)
            marker = @_processError(errorMsg, errorLevel, errorLine)
            @_markers.push(marker)
          
      catch error
        #here handle any error not already managed by coffeelint
        errorLine = error.message.split("line ")
        errorLine = parseInt(errorLine[errorLine.length - 1],10)-1
        errorMsg = error.message
        
        if not isNaN(errorLine)
          marker = @_processError(errorMsg, "error", errorLine)
          @_markers.push(marker)  
        ###
        try
        catch error
          console.log "ERROR #{error} in adding error marker"
        ###

    #this could also be solved by letting the event listeners access the list of available undos & redos ?
    updateUndoRedo: () =>
      redos = @editor.historySize().redo
      undos = @editor.historySize().undo
      if redos >0
        @vent.trigger("file:redoAvailable", @)
      else
        @vent.trigger("file:redoUnAvailable", @)
      if undos >0
        @vent.trigger("file:undoAvailable", @)
      else
        @vent.trigger("file:undoUnAvailable", @)
        
    undo:=>
      undoes = @editor.historySize().undo
      if undoes > 0
        @editor.undo()
        
    redo:=>
      redoes = @editor.historySize().redo
      if redoes >0
        @editor.redo()
    
    #onDomRefresh:=>
    #  @editor.refresh()
      
    setHeight:(height)=>
      @editor.getWrapperElement().style.height = height+ 'px';
      @editor.refresh()
    
    _setupEventHandlers:=>
      foldFunction = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)
      
      @editor.on "change", (cm, change)=>
        @_updateHints()
        @model.content = @editor.getValue()
        @updateUndoRedo()
      
      @editor.on "gutterClick",(cm, line, gutter, clickEvent)=>
        foldFunction(cm,cm.getCursor().line)
      
      @editor.on "cursorActivity", (cm) =>
        cursor = @editor.getCursor()
        @editor.removeLineClass(@hlLine,"activeline")
        @hlLine = @editor.addLineClass(cursor.line, null, "activeline")
        
        infoText = "Line: #{cursor.line} Column: #{cursor.ch}"
        @ui.infoFooter.text(infoText)
        #console.log "blah"
        #console.log @editor.getCursor()
    
    onRender:=>
      $(".CodeMirror").css("font-size","#{@settings.get('fontSize')}em")
    
    onDomRefresh:=>
      CodeMirror.commands.autocomplete = (cm) ->
        CodeMirror.showHint(cm, CodeMirror.coffeeSCadHint)
      
      @editor = CodeMirror.fromTextArea @ui.codeBlock.get(0),
        theme: "lesser-dark"
        mode:"coffeescript"
        
        tabSize: 2
        indentUnit:2
        indentWithTabs:false
        lineNumbers:true
        gutter: true
        matchBrackets:true
        undoDepth: @settings.get("undoDepth")
        firstLineNumber:@settings.get("startLine")
        highlightSelectionMatches: true
      
        gutters: ["lintAndErrorsGutter", "CodeMirror-linenumbers"]
        extraKeys: 
          Tab:(cm)->
              if (cm.somethingSelected()) 
                cm.indentSelection("add")
              else cm.replaceSelection("  ", "end")
          "Ctrl-Space": "autocomplete"
          "Ctrl-D":(cm)->
            doc = cm.getDoc()
            line = doc.sel.anchor.line
            cm.getDoc().removeLine(line)
            return false
      
      @$el.attr('id', @model.name)
      @hlLine=  @editor.addLineClass(0, "activeline")
      @_setupEventHandlers()

      setTimeout ( =>
        @editor.refresh()
        $(".CodeMirror").css("font-size","#{@settings.get('fontSize')}em")
      ), 2 #necessary hack
      
      
  return FileCodeView