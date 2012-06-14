/*
 * jQuery File Upload Plugin JS Example 5.0.2
 * https://github.com/blueimp/jQuery-File-Upload
 *
 * Copyright 2010, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://creativecommons.org/licenses/MIT/
 */

/*jslint nomen: true */
/*global $ */

var filestoupload =0;      
var files_done =0;      
var error_string ='';      
//200 MB  max file size 
var max_file_size = 200000000;
var max_file_size_str = "200 MB";
//500 MB max total upload size
var max_total_file_size = 500000000;
var max_total_file_size_str = "500 MB";

$(function () {
    'use strict';

    $("#upload_tooltip").hide();
    $("#main_upload_start_span").mousemove(function(e){
       if ( !$('#terms_of_service')[0].checked){
        $("#upload_tooltip").show();
        $("#upload_tooltip").css({
            top: (e.clientY+5)+ "px",
            left: (e.clientX+5) + "px"
        });
       } else {
         $("#upload_tooltip").hide();
       }
    });
    $("#main_upload_start_span").mouseout(function(e){
        $("#upload_tooltip").hide();
    });
    $("#main_upload_start_span").mouseleave(function(e){
        $("#upload_tooltip").hide();
    });
    $('#terms_of_service').click(function () {
        $('#main_upload_start')[0].disabled = !this.checked
        $("#upload_tooltip").hide();
    });

    // Initialize the jQuery File Upload widget:
    $('#fileupload').fileupload();
    $('#fileupload').bind("fileuploadstop", function(){
      if ((files_done == filestoupload)&&(files_done >0)){
         //var loc = $("#redirect-loc").html()+"?file_count="+filestoupload
         var loc = $("#redirect-loc").html()
         $(location).attr('href',loc);
      // some error occured       
      } else if (error_string.length > 0){
         if (files_done == 0) {
            $("#fail").fadeIn('slow')
         } else {
            $("#partial_fail").fadeIn('slow')
         }          
         $("#errmsg").html(error_string);
         $("#errmsg").fadeIn('slow');
      }
    }); 

    // count the number of uploaded files to send to edit
    $('#fileupload').bind("fileuploadadd", function(e, data){
      filestoupload++;
    });
    
    // check the validation on if the file type is not accepted just click cancel for the user as we do not want them to see all the hidden files
    $('#fileupload').bind("fileuploadadded", function(e, data){
        if (data.files[0].error == 'acceptFileTypes'){
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
        }
        var total_sz = parseInt($('#total_upload_size').val()) + data.files[0].size;
        // is file size too big
        if (data.files[0].size > max_file_size) {
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
          $("#errmsg").html(data.files[0].name + " is too big. No files over " + max_file_size_str + " can be uploaded.");
          $("#errmsg").fadeIn('slow');
        }
        // cumulative upload file size is too big
        else if( total_sz > max_total_file_size) {
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
          $("#errmsg").html("All files selected from " + data.files[0].name + " and after will not be uploaded because your total upload is too big. You may not upload more than " + max_total_file_size_str + " in one upload.");
          $("#errmsg").fadeIn('slow');
        }
        else {
          $('#total_upload_size').val( parseInt($('#total_upload_size').val()) + data.files[0].size );
        }
              
    });

    // count the number of files completed and ready to send to edit                          
    $('#fileupload').bind("fileuploaddone", function(e, data){
     var file = ($.isArray(data.result) && data.result[0]) || {error: 'emptyResult'};
     if (!file.error) {
       files_done++;     
     }else {
       if (error_string.length > 0) {
          error_string +='<br/>';
       }
       error_string +=file.error;
     }
    
    });

    // on fail if abort (aka cancel) decrease the number of uploaded files to send
    $('#fileupload').bind("fileuploadfail", function(e, data){ 
      if (data.errorThrown == 'abort') {
         filestoupload--;
         if ((files_done == filestoupload)&&(files_done >0)){
             var loc = $("#redirect-loc").html()+"?file_count="+filestoupload
             $(location).attr('href',loc);
         }
      } else {
       if (error_string.length > 0) {
          error_string +='<br/>';
       }
       error_string +=data.errorThrown+": "+data.textStatus;
      }
    });
    
    
    // Load existing files:
    $.getJSON($('#fileupload form').prop('action'), function (files) {
        var fu = $('#fileupload').data('fileupload');
        fu._adjustMaxNumberOfFiles(-files.length);
        fu._renderDownload(files)
            .appendTo($('#fileupload .files'))
            .fadeIn(function () {
                // Fix for IE7 and lower:
                $(this).show();
            });
    });

    // Open download dialogs via iframes,
    // to prevent aborting current uploads:
    $('#fileupload .files a:not([target^=_blank])').live('click', function (e) {
        e.preventDefault();
        $('<iframe style="display:none;"></iframe>')
            .prop('src', this.href)
            .appendTo('body');
    });

});
