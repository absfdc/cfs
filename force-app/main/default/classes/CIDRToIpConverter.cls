/*------------------------------------------------------------
Author:         Lalit Mistry
Company:        Arxxus Technology Partners
Description:    utility class for converting ip address in cidr format to xxx.xxx.xxx.xxx format
Inputs:         "ipInCidrFormat" - ip address in cidr format xx.xx.xx.xx/xx
Test Class:     CIDRToIpConverter_Test
History:
------------------------------------------------------------*/
public class CIDRToIpConverter {

    private Integer baseIPnumeric;
    private Integer netmaskNumeric;
    private String firstIP;
    private String lastIP;
    
    private static final Integer BITS_IN_ONE_BYTE = 8;
    private static final Integer BITS_IN_THREE_BYTES = 24;
    private static final Integer BITS_IN_FOUR_BYTES = 32;
    private static final Integer MAX_INT_FOR_8_BITS = 255;
    private static final Integer IP_CIDR_FORMAT_PARTS =2;
    private static final Integer IP4_OCTET_SIZE = 4;
    
    public CIDRToIpConverter(String ipInCidrFormat) {
        List<String> ipComponent = ipInCidrFormat.split('\\/');
        if (ipComponent.size() != IP_CIDR_FORMAT_PARTS) {
            throw new InvalidCIDRFormatException('Invalid CIDR format ' 
                            + ipInCidrFormat + ', should be: xx.xx.xx.xx/xx');
        }
        String symbolicIP = ipComponent[0];
        String symbolicCIDR = ipComponent[1];

        Integer numericCIDR = Integer.valueOf(symbolicCIDR);
        if (numericCIDR > BITS_IN_FOUR_BYTES) {
            throw new InvalidCIDRFormatException('CIDR can not be greater than 32');
        }

        //Get IP
        ipComponent = symbolicIP.split('\\.');
        if (ipComponent.size()!= IP4_OCTET_SIZE) {
            throw new InvalidCIDRFormatException('Invalid IP address: ' + symbolicIP);
        }

        Integer i = BITS_IN_THREE_BYTES; //bits in 3 bytes
        baseIPnumeric = 0;
    
        for (Integer n = 0; n < ipComponent.size(); n++) {
            Integer value = Integer.valueOf(ipComponent[n]);
            if (value != (value & MAX_INT_FOR_8_BITS)) {
                throw new InvalidCIDRFormatException('Invalid IP address: ' + symbolicIP);
            }
            baseIPnumeric += value << i;
            i -= BITS_IN_ONE_BYTE; //reduce i by number of bits in one byte
        }

        //Get netmask
        if (numericCIDR < BITS_IN_ONE_BYTE)
            throw new InvalidCIDRFormatException('Netmask CIDR can not be less than 8');
        netmaskNumeric = -1; //Integer representation of 0xffffffff
        netmaskNumeric = netmaskNumeric << (BITS_IN_FOUR_BYTES - numericCIDR);
    }

    private String convertNumericIpToSymbolic(Integer ip) {
        String symbolicIp = '';
        for (Integer shift = BITS_IN_THREE_BYTES; shift > 0; shift -= BITS_IN_ONE_BYTE) {
            // process 3 bytes, from high order byte down.
            System.debug('Current symbolicIp: ' + symbolicIp + ' Ip: ' + ip);
            symbolicIp = symbolicIp + (String.valueOf((ip >>> shift) & MAX_INT_FOR_8_BITS));
            symbolicIp = symbolicIp + '.';
        }
        symbolicIp = symbolicIp + (String.valueOf(ip & MAX_INT_FOR_8_BITS));
        return symbolicIp;
    }

    private void getHostAddressRange() {
        Integer numberOfBits;
        for (numberOfBits = 0; numberOfBits < BITS_IN_FOUR_BYTES; numberOfBits++) {
            if ((netmaskNumeric << numberOfBits) == 0)
                break;
        }
        System.debug('Number of bits: ' + numberOfBits);
        Integer numberOfIPs = 0;
        for (Integer n = 0; n < (BITS_IN_FOUR_BYTES - numberOfBits); n++) {
            numberOfIPs = numberOfIPs << 1;
            numberOfIPs = numberOfIPs | 1;
        }
        System.debug('Number of ips: ' + numberOfIPs);
        Integer baseIP = baseIPnumeric & netmaskNumeric;
        firstIP = convertNumericIpToSymbolic(baseIP );
        lastIP = convertNumericIpToSymbolic(baseIP + numberOfIPs );
    }

    /*------------------------------------------------------------
    Author:         Lalit Mistry
    Company:        Arxxus Technology Partners
    Description:    utility method for converting cidr ip address to xxx.xxx.xxx.xxx format
    Inputs:         
    Returns:        Set<String> returns set of ip address covered under given cidr ip address
    History:
    ------------------------------------------------------------*/
    public Set<String> getIpAddresses() {
        Set<String> ipAddresses = new Set<String>();
        getHostAddressRange();
        if(!String.isBlank(this.firstIP) && !String.isBlank(this.lastIP)) {
            Long startAddress = ipToLong(this.firstIP);
            Long endAddress = ipToLong(this.lastIP);
            
            for(Long ip = startAddress; ip <= endAddress; ip++) {
                ipAddresses.add(longToIp(ip));
            }
        }
        return ipAddresses;
    }
    
    private Long ipToLong(String ipAddress) {    
        List<String> ipAddressInList = ipAddress.split('\\.');   
        Long result = 0L;
        for (Integer i = 0; i < ipAddressInList.size(); i++) {   
            Integer power = 3 - i;
            Integer ip = Integer.valueOf(ipAddressInList[i]);
            result +=  ip *  (Long)Math.pow(256, power);     
        } 
        return result;
    }
    
    private String longToIp(Long ip) {
        String result = '';  
        for (Integer i = 0; i < IP4_OCTET_SIZE; i++) {    
            if(i != 0) {
                result = String.valueOf((ip & 255)) +  '.' + result ;    
            } else {
                result = String.valueOf((ip & 255)) +  result ;  
            }    
            ip = ip >> 8;
        }
        return result;
    }

    public class InvalidCIDRFormatException extends Exception {}
}