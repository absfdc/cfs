@isTest
private class HTMLRemover_Test {
    
    @isTest static void test_method_remove() {
        // Implement test code

        String htmlString = '<html><body>Hi,<br/> This is<p>a</p> test &amp; test <p />email</body></html>';
        String output = HTMLRemover.remove(htmlString);
        System.debug('output.........'+output);
        System.debug('output length.........'+output.length());
        String expectedOutput = 'Hi,\n This is\n\na test & test \n\nemail';
        System.debug('expectedOutput.........'+expectedOutput);
        System.debug('expectedOutput length.........'+expectedOutput.length());
        System.assertEquals(output,expectedOutput);
    }
    
}