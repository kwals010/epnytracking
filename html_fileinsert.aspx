<%@ Page language="c#"%>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<script runat="server" lang="c#" id="Script1">

/* This web page takes a stand-alone web page from a URL and formats it for use in Epiphany email 
 * marketing using the fileinsert function. It does a screenscape of the page and regular expression 
 * substitutions for URL tracking. If additional parameters are specified in the query string, it 
 * replaces the names with the values. The names on the web page must be enclosed in tic marks (e.g.
 * `name`).
 * 
 * Author: Keith Walsh
 * Company: Microsoft
 * Date: 8/19/2013
 */

    private void Page_Load(object sender, System.EventArgs e)
    {

        // Variable for the final output of this process 
        String outputHTMLPage = "";
        String newMsg = "";
        // Check for the GUID embedded in all valid pages
        String sdGuid = "--REMOVED FOR SECURITY--";   
        
        //Check to make sure a URL is in the query string.
        if (Request.QueryString["url"] == "" || Request.QueryString["url"] == null)
        {
            // If no URL name->value pair, return error message to the ID
            outputHTMLPage = "<html><head><title>Error</title></head><body>Error. No value for key \"url\" in the url.<br />" +
                "The following URL will prevent the mail from going through Epiphany <br />" +
               "`URLTrackraw(\"http://thisIsaSkydriveEBMerrorURL-noURL.wrong\")`</body></html>";

        }
        else
        {
            // Retrieve the html content from the page
            String strResult;
            WebRequest objRequest = HttpWebRequest.Create(Request.QueryString["url"]);
            WebResponse objResponse = objRequest.GetResponse();
            using (StreamReader sr =
            new StreamReader(objResponse.GetResponseStream()))
            {
                strResult = sr.ReadToEnd();
                sr.Close();
            }
            if (!strResult.Contains(sdGuid))
            {
                outputHTMLPage = "<html><head><title>Error</title></head><body>Error. GUID not found.<br />" +
                "The following URL will prevent the mail from going through Epiphany <br />" +
                "`URLTrackraw(\"http://thisIsaSkydriveEBMerrorURL-noGUID.wrong\")`</body></html>";
             }
            else
            {


                // Add Epiphany URL tracking to all links.
                String plainURL = @"(?i)(href=)(""\S+""|'\S+')";
                newMsg = Regex.Replace(strResult, plainURL, "$1`URLTrackraw($2)`");

                // Capture all of the name->value pairs in the query string.
                String querystring = null;
                String currurl = HttpContext.Current.Request.RawUrl;
                int iqs = currurl.IndexOf('?');

                // Parse the query string variables into a NameValueCollection.
                querystring = (iqs < currurl.Length - 1) ? currurl.Substring(iqs + 1) : String.Empty;
                String decodedqs = WebUtility.HtmlDecode(querystring);
                NameValueCollection qscoll = HttpUtility.ParseQueryString(decodedqs);

                //Iterate through the collection and replace all the names in the message with the values.
                newMsg = Regex.Replace(newMsg, "&#96;", "`"); //Replace all html entity back tic marks with actual marks

                foreach (String s in qscoll.AllKeys)
                {
                    String sub = "`" + s + "`";
                    newMsg = Regex.Replace(newMsg, sub, qscoll[s]);
                }


                // Swap out the view in browser functionality
                String vibURL = @"(?i)`ViewInBrowser\(""(.*)""\)`";
                newMsg = Regex.Replace(newMsg, vibURL, "<a href=\"http://skydriveemail.cloudapp.net/viewinbrowser.aspx?" + querystring + " \">$1</a>");

                outputHTMLPage = newMsg;
            }

            
        } 
        
        
        // Output the final message to page.
        litHTMLfromScrapedPage.Text = outputHTMLPage;
    }
</script>
<form id="Form1" runat="server">
<asp:Literal ID="litHTMLfromScrapedPage" Runat="server" />
</form>