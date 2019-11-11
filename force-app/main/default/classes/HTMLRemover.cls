/*-----------------------------------------------------------------------------------
Author:        Vishal Taware
Company:       Arxxus.com
Description:   This class  will strip HTML from input string.

Test Class:    HTMLRemover_Test
History
16/07/2015     Vishal Taware      Created
05/08/2015     Albert James       Modified to substitute <p[ /]> to double newlines
-----------------------------------------------------------------------------------*/
public class HTMLRemover {
    
    /*-----------------------------------------------------------------------------------
    Author:        Vishal Taware
    Company:       Arxxus.com
    Description:   This method will replace all <br/> with \n
                   and remove all html tags.

    Inputs:        String in html format
    History
    <Date>         <Authors Name>     <Brief Description of Change>
    16/07/2015     Vishal Taware      Created
    -----------------------------------------------------------------------------------*/
    public static String remove(String htmlInput){
        try{

            System.debug('htmlInput.....'+htmlInput);
            
            //first replace all <BR> tags with \n to support new lines
            string result = htmlInput.replaceAll('<br/>', '\n');
            result = result.replaceAll('<br />', '\n');
            result = result.replaceAll('<br>', '\n');
            result = result.replaceAll('<p>', '\n\n');   // AJJ modified to double newline
            result = result.replaceAll('<p />', '\n\n'); // added AJJ 20150805
            result = result.replaceAll('<p/>', '\n\n');  // added AJJ 20150805
            System.debug('result removed br.....'+result);

            // Next, use a regular expression to match all HTML/XML tags
            string HTML_TAG_PATTERN = '<.*?>';

            // compile the pattern     
            pattern myPattern = pattern.compile(HTML_TAG_PATTERN);

            // get your matcher instance
            matcher myMatcher = myPattern.matcher(result);

            //remove the tags     
            result = myMatcher.replaceAll('');
            
            // Lastly, unescape any escaped characters (e.g. &amp; &lt; etc)
            result = result.unescapeHtml4();

            System.debug('result.....'+result);

            return result;
        }Catch(Exception exc){
            System.debug('Recieved an exception while removing html from Given string...'+exc+'\n');
            return htmlInput;
        }
    }
}