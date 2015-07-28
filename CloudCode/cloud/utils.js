/* global Parse */

exports.recordDateString = function(date) {
    var year = date.getFullYear().toString();
   var month = (date.getMonth()+1).toString(); // getMonth() is zero-based
   var day = date.getDate().toString();
   if (month.length < 2) month = '0' + month;
   if (day.length < 2) day = '0' + day;
    
   return [year, month, day].join('-');
}

exports.formatTime = function(time) {
    var hours = time/3600;
    var postfix = hours >= 12 ? "PM" : "AM";

    if (hours == 0) {
        return "12 " + postfix;
    } else if (hours > 12) {
        return (hours - 12) + " " + postfix;
    } else {
        return hours + " " + postfix;
    }
}