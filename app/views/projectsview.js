// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function(require) {
    var $, FileView, FilesView, mF_template, marionette, sF_template, _;
    $ = require('jquery');
    _ = require('underscore');
    marionette = require('marionette');
    mF_template = require("text!templates/multiFileView.tmpl");
    sF_template = require("text!templates/singleFileView.tmpl");
    FileView = (function(_super) {

      __extends(FileView, _super);

      function FileView() {
        return FileView.__super__.constructor.apply(this, arguments);
      }

      FileView.prototype.template = sF_template;

      FileView.prototype.tagName = "li";

      return FileView;

    })(marionette.ItemView);
    FilesView = (function(_super) {

      __extends(FilesView, _super);

      FilesView.prototype.tagName = "ul";

      function FilesView(options) {
        FilesView.__super__.constructor.call(this, options);
        this.itemView = FileView;
      }

      return FilesView;

    })(marionette.CollectionView);
    return FilesView;
  });

}).call(this);
