public class DFSIAttachment {

	public String Name;
	public Blob Body;
	public String Id;

	public static List<DFSIAttachment> parse(String jsonStr) {
		if(jsonstr == null || jsonstr == '')
			return null;
		return (List<DFSIAttachment>) JSON.deserialize(jsonstr, List<DFSIAttachment>.class);
	}

	public Attachment convert() {
		return new Attachment(name = this.Name, body = this.Body);
	}
}