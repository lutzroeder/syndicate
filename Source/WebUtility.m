
#import "WebUtility.h"

@implementation WebUtility

+ (NSString*) htmlEncode:(NSString*)string
{
    BOOL encode = NO;
    for (int i = 0; i < [string length]; i++)
    {
        unichar c = [string characterAtIndex:i];
        if (c == '&' || c == '"' || c == '<' || c == '>' || c > 159)
        {
            encode = YES;
            break;
        }
    }
    
    if (!encode)
    {
        return string;
    }

    NSUInteger length = [string length];
    NSMutableString* builder = [[NSMutableString alloc] initWithCapacity:length];

    for (int i = 0; i < length; i++)
    {
        unichar c = [string characterAtIndex:i];
        switch (c)
        {
            case '&':
                [builder appendString:@"&amp;"];
                break;
            case '>':
                [builder appendString:@"&gt;"];
                break;
            case '<':
                [builder appendString:@"&lt;"];
                break;
            case '"':
                [builder appendString:@"&quot;"];
                break;
            default:
                if (c > 159)
                {
                    [builder appendString:@"&#"];
                    [builder appendString:[[NSNumber numberWithInt:c] stringValue]];
                    [builder appendString:@";"];                    
                }
                else
                {
                    [builder appendString:[NSString stringWithCharacters:&c length:1]];
                }
                break;
        }
    }
    
    return [builder autorelease];
}

+ (NSString*) htmlDecode:(NSString*)string
{
    static NSMutableDictionary* _entities = nil;
    if (_entities == nil)
    {
        _entities = [[NSMutableDictionary alloc] init];
        [_entities setObject:@"\u00A0" forKey:@"nbsp"];
        [_entities setObject:@"\u00A0" forKey:@"nbsp"];
        [_entities setObject:@"\u00A1" forKey:@"iexcl"];
        [_entities setObject:@"\u00A2" forKey:@"cent"];
        [_entities setObject:@"\u00A3" forKey:@"pound"];
        [_entities setObject:@"\u00A4" forKey:@"curren"];
        [_entities setObject:@"\u00A5" forKey:@"yen"];
        [_entities setObject:@"\u00A6" forKey:@"brvbar"];
        [_entities setObject:@"\u00A7" forKey:@"sect"];
        [_entities setObject:@"\u00A8" forKey:@"uml"];
        [_entities setObject:@"\u00A9" forKey:@"copy"];
        [_entities setObject:@"\u00AA" forKey:@"ordf"];
        [_entities setObject:@"\u00AB" forKey:@"laquo"];
        [_entities setObject:@"\u00AC" forKey:@"not"];
        [_entities setObject:@"\u00AD" forKey:@"shy"];
        [_entities setObject:@"\u00AE" forKey:@"reg"];
        [_entities setObject:@"\u00AF" forKey:@"macr"];
        [_entities setObject:@"\u00B0" forKey:@"deg"];
        [_entities setObject:@"\u00B1" forKey:@"plusmn"];
        [_entities setObject:@"\u00B2" forKey:@"sup2"];
        [_entities setObject:@"\u00B3" forKey:@"sup3"];
        [_entities setObject:@"\u00B4" forKey:@"acute"];
        [_entities setObject:@"\u00B5" forKey:@"micro"];
        [_entities setObject:@"\u00B6" forKey:@"para"];
        [_entities setObject:@"\u00B7" forKey:@"middot"];
        [_entities setObject:@"\u00B8" forKey:@"cedil"];
        [_entities setObject:@"\u00B9" forKey:@"sup1"];
        [_entities setObject:@"\u00BA" forKey:@"ordm"];
        [_entities setObject:@"\u00BB" forKey:@"raquo"];
        [_entities setObject:@"\u00BC" forKey:@"frac14"];
        [_entities setObject:@"\u00BD" forKey:@"frac12"];
        [_entities setObject:@"\u00BE" forKey:@"frac34"];
        [_entities setObject:@"\u00BF" forKey:@"iquest"];
        [_entities setObject:@"\u00C0" forKey:@"Agrave"];
        [_entities setObject:@"\u00C1" forKey:@"Aacute"];
        [_entities setObject:@"\u00C2" forKey:@"Acirc"];
        [_entities setObject:@"\u00C3" forKey:@"Atilde"];
        [_entities setObject:@"\u00C4" forKey:@"Auml"];
        [_entities setObject:@"\u00C5" forKey:@"Aring"];
        [_entities setObject:@"\u00C6" forKey:@"AElig"];
        [_entities setObject:@"\u00C7" forKey:@"Ccedil"];
        [_entities setObject:@"\u00C8" forKey:@"Egrave"];
        [_entities setObject:@"\u00C9" forKey:@"Eacute"];
        [_entities setObject:@"\u00CA" forKey:@"Ecirc"];
        [_entities setObject:@"\u00CB" forKey:@"Euml"];
        [_entities setObject:@"\u00CC" forKey:@"Igrave"];
        [_entities setObject:@"\u00CD" forKey:@"Iacute"];
        [_entities setObject:@"\u00CE" forKey:@"Icirc"];
        [_entities setObject:@"\u00CF" forKey:@"Iuml"];
        [_entities setObject:@"\u00D0" forKey:@"ETH"];
        [_entities setObject:@"\u00D1" forKey:@"Ntilde"];
        [_entities setObject:@"\u00D2" forKey:@"Ograve"];
        [_entities setObject:@"\u00D3" forKey:@"Oacute"];
        [_entities setObject:@"\u00D4" forKey:@"Ocirc"];
        [_entities setObject:@"\u00D5" forKey:@"Otilde"];
        [_entities setObject:@"\u00D6" forKey:@"Ouml"];
        [_entities setObject:@"\u00D7" forKey:@"times"];
        [_entities setObject:@"\u00D8" forKey:@"Oslash"];
        [_entities setObject:@"\u00D9" forKey:@"Ugrave"];
        [_entities setObject:@"\u00DA" forKey:@"Uacute"];
        [_entities setObject:@"\u00DB" forKey:@"Ucirc"];
        [_entities setObject:@"\u00DC" forKey:@"Uuml"];
        [_entities setObject:@"\u00DD" forKey:@"Yacute"];
        [_entities setObject:@"\u00DE" forKey:@"THORN"];
        [_entities setObject:@"\u00DF" forKey:@"szlig"];
        [_entities setObject:@"\u00E0" forKey:@"agrave"];
        [_entities setObject:@"\u00E1" forKey:@"aacute"];
        [_entities setObject:@"\u00E2" forKey:@"acirc"];
        [_entities setObject:@"\u00E3" forKey:@"atilde"];
        [_entities setObject:@"\u00E4" forKey:@"auml"];
        [_entities setObject:@"\u00E5" forKey:@"aring"];
        [_entities setObject:@"\u00E6" forKey:@"aelig"];
        [_entities setObject:@"\u00E7" forKey:@"ccedil"];
        [_entities setObject:@"\u00E8" forKey:@"egrave"];
        [_entities setObject:@"\u00E9" forKey:@"eacute"];
        [_entities setObject:@"\u00EA" forKey:@"ecirc"];
        [_entities setObject:@"\u00EB" forKey:@"euml"];
        [_entities setObject:@"\u00EC" forKey:@"igrave"];
        [_entities setObject:@"\u00ED" forKey:@"iacute"];
        [_entities setObject:@"\u00EE" forKey:@"icirc"];
        [_entities setObject:@"\u00EF" forKey:@"iuml"];
        [_entities setObject:@"\u00F0" forKey:@"eth"];
        [_entities setObject:@"\u00F1" forKey:@"ntilde"];
        [_entities setObject:@"\u00F2" forKey:@"ograve"];
        [_entities setObject:@"\u00F3" forKey:@"oacute"];
        [_entities setObject:@"\u00F4" forKey:@"ocirc"];
        [_entities setObject:@"\u00F5" forKey:@"otilde"];
        [_entities setObject:@"\u00F6" forKey:@"ouml"];
        [_entities setObject:@"\u00F7" forKey:@"divide"];
        [_entities setObject:@"\u00F8" forKey:@"oslash"];
        [_entities setObject:@"\u00F9" forKey:@"ugrave"];
        [_entities setObject:@"\u00FA" forKey:@"uacute"];
        [_entities setObject:@"\u00FB" forKey:@"ucirc"];
        [_entities setObject:@"\u00FC" forKey:@"uuml"];
        [_entities setObject:@"\u00FD" forKey:@"yacute"];
        [_entities setObject:@"\u00FE" forKey:@"thorn"];
        [_entities setObject:@"\u00FF" forKey:@"yuml"];
        [_entities setObject:@"\u0192" forKey:@"fnof"];
        [_entities setObject:@"\u0391" forKey:@"Alpha"];
        [_entities setObject:@"\u0392" forKey:@"Beta"];
        [_entities setObject:@"\u0393" forKey:@"Gamma"];
        [_entities setObject:@"\u0394" forKey:@"Delta"];
        [_entities setObject:@"\u0395" forKey:@"Epsilon"];
        [_entities setObject:@"\u0396" forKey:@"Zeta"];
        [_entities setObject:@"\u0397" forKey:@"Eta"];
        [_entities setObject:@"\u0398" forKey:@"Theta"];
        [_entities setObject:@"\u0399" forKey:@"Iota"];
        [_entities setObject:@"\u039A" forKey:@"Kappa"];
        [_entities setObject:@"\u039B" forKey:@"Lambda"];
        [_entities setObject:@"\u039C" forKey:@"Mu"];
        [_entities setObject:@"\u039D" forKey:@"Nu"];
        [_entities setObject:@"\u039E" forKey:@"Xi"];
        [_entities setObject:@"\u039F" forKey:@"Omicron"];
        [_entities setObject:@"\u03A0" forKey:@"Pi"];
        [_entities setObject:@"\u03A1" forKey:@"Rho"];
        [_entities setObject:@"\u03A3" forKey:@"Sigma"];
        [_entities setObject:@"\u03A4" forKey:@"Tau"];
        [_entities setObject:@"\u03A5" forKey:@"Upsilon"];
        [_entities setObject:@"\u03A6" forKey:@"Phi"];
        [_entities setObject:@"\u03A7" forKey:@"Chi"];
        [_entities setObject:@"\u03A8" forKey:@"Psi"];
        [_entities setObject:@"\u03A9" forKey:@"Omega"];
        [_entities setObject:@"\u03B1" forKey:@"alpha"];
        [_entities setObject:@"\u03B2" forKey:@"beta"];
        [_entities setObject:@"\u03B3" forKey:@"gamma"];
        [_entities setObject:@"\u03B4" forKey:@"delta"];
        [_entities setObject:@"\u03B5" forKey:@"epsilon"];
        [_entities setObject:@"\u03B6" forKey:@"zeta"];
        [_entities setObject:@"\u03B7" forKey:@"eta"];
        [_entities setObject:@"\u03B8" forKey:@"theta"];
        [_entities setObject:@"\u03B9" forKey:@"iota"];
        [_entities setObject:@"\u03BA" forKey:@"kappa"];
        [_entities setObject:@"\u03BB" forKey:@"lambda"];
        [_entities setObject:@"\u03BC" forKey:@"mu"];
        [_entities setObject:@"\u03BD" forKey:@"nu"];
        [_entities setObject:@"\u03BE" forKey:@"xi"];
        [_entities setObject:@"\u03BF" forKey:@"omicron"];
        [_entities setObject:@"\u03C0" forKey:@"pi"];
        [_entities setObject:@"\u03C1" forKey:@"rho"];
        [_entities setObject:@"\u03C2" forKey:@"sigmaf"];
        [_entities setObject:@"\u03C3" forKey:@"sigma"];
        [_entities setObject:@"\u03C4" forKey:@"tau"];
        [_entities setObject:@"\u03C5" forKey:@"upsilon"];
        [_entities setObject:@"\u03C6" forKey:@"phi"];
        [_entities setObject:@"\u03C7" forKey:@"chi"];
        [_entities setObject:@"\u03C8" forKey:@"psi"];
        [_entities setObject:@"\u03C9" forKey:@"omega"];
        [_entities setObject:@"\u03D1" forKey:@"thetasym"];
        [_entities setObject:@"\u03D2" forKey:@"upsih"];
        [_entities setObject:@"\u03D6" forKey:@"piv"];
        [_entities setObject:@"\u2022" forKey:@"bull"];
        [_entities setObject:@"\u2026" forKey:@"hellip"];
        [_entities setObject:@"\u2032" forKey:@"prime"];
        [_entities setObject:@"\u2033" forKey:@"Prime"];
        [_entities setObject:@"\u203E" forKey:@"oline"];
        [_entities setObject:@"\u2044" forKey:@"frasl"];
        [_entities setObject:@"\u2118" forKey:@"weierp"];
        [_entities setObject:@"\u2111" forKey:@"image"];
        [_entities setObject:@"\u211C" forKey:@"real"];
        [_entities setObject:@"\u2122" forKey:@"trade"];
        [_entities setObject:@"\u2135" forKey:@"alefsym"];
        [_entities setObject:@"\u2190" forKey:@"larr"];
        [_entities setObject:@"\u2191" forKey:@"uarr"];
        [_entities setObject:@"\u2192" forKey:@"rarr"];
        [_entities setObject:@"\u2193" forKey:@"darr"];
        [_entities setObject:@"\u2194" forKey:@"harr"];
        [_entities setObject:@"\u21B5" forKey:@"crarr"];
        [_entities setObject:@"\u21D0" forKey:@"lArr"];
        [_entities setObject:@"\u21D1" forKey:@"uArr"];
        [_entities setObject:@"\u21D2" forKey:@"rArr"];
        [_entities setObject:@"\u21D3" forKey:@"dArr"];
        [_entities setObject:@"\u21D4" forKey:@"hArr"];
        [_entities setObject:@"\u2200" forKey:@"forall"];
        [_entities setObject:@"\u2202" forKey:@"part"];
        [_entities setObject:@"\u2203" forKey:@"exist"];
        [_entities setObject:@"\u2205" forKey:@"empty"];
        [_entities setObject:@"\u2207" forKey:@"nabla"];
        [_entities setObject:@"\u2208" forKey:@"isin"];
        [_entities setObject:@"\u2209" forKey:@"notin"];
        [_entities setObject:@"\u220B" forKey:@"ni"];
        [_entities setObject:@"\u220F" forKey:@"prod"];
        [_entities setObject:@"\u2211" forKey:@"sum"];
        [_entities setObject:@"\u2212" forKey:@"minus"];
        [_entities setObject:@"\u2217" forKey:@"lowast"];
        [_entities setObject:@"\u221A" forKey:@"radic"];
        [_entities setObject:@"\u221D" forKey:@"prop"];
        [_entities setObject:@"\u221E" forKey:@"infin"];
        [_entities setObject:@"\u2220" forKey:@"ang"];
        [_entities setObject:@"\u2227" forKey:@"and"];
        [_entities setObject:@"\u2228" forKey:@"or"];
        [_entities setObject:@"\u2229" forKey:@"cap"];
        [_entities setObject:@"\u222A" forKey:@"cup"];
        [_entities setObject:@"\u222B" forKey:@"int"];
        [_entities setObject:@"\u2234" forKey:@"there4"];
        [_entities setObject:@"\u223C" forKey:@"sim"];
        [_entities setObject:@"\u2245" forKey:@"cong"];
        [_entities setObject:@"\u2248" forKey:@"asymp"];
        [_entities setObject:@"\u2260" forKey:@"ne"];
        [_entities setObject:@"\u2261" forKey:@"equiv"];
        [_entities setObject:@"\u2264" forKey:@"le"];
        [_entities setObject:@"\u2265" forKey:@"ge"];
        [_entities setObject:@"\u2282" forKey:@"sub"];
        [_entities setObject:@"\u2283" forKey:@"sup"];
        [_entities setObject:@"\u2284" forKey:@"nsub"];
        [_entities setObject:@"\u2286" forKey:@"sube"];
        [_entities setObject:@"\u2287" forKey:@"supe"];
        [_entities setObject:@"\u2295" forKey:@"oplus"];
        [_entities setObject:@"\u2297" forKey:@"otimes"];
        [_entities setObject:@"\u22A5" forKey:@"perp"];
        [_entities setObject:@"\u22C5" forKey:@"sdot"];
        [_entities setObject:@"\u2308" forKey:@"lceil"];
        [_entities setObject:@"\u2309" forKey:@"rceil"];
        [_entities setObject:@"\u230A" forKey:@"lfloor"];
        [_entities setObject:@"\u230B" forKey:@"rfloor"];
        [_entities setObject:@"\u2329" forKey:@"lang"];
        [_entities setObject:@"\u232A" forKey:@"rang"];
        [_entities setObject:@"\u25CA" forKey:@"loz"];
        [_entities setObject:@"\u2660" forKey:@"spades"];
        [_entities setObject:@"\u2663" forKey:@"clubs"];
        [_entities setObject:@"\u2665" forKey:@"hearts"];
        [_entities setObject:@"\u2666" forKey:@"diams"];
        [_entities setObject:@"\"" forKey:@"quot"];
        [_entities setObject:@"&" forKey:@"amp"];
        [_entities setObject:@"<" forKey:@"lt"];
        [_entities setObject:@">" forKey:@"gt"];
        [_entities setObject:@"\u0152" forKey:@"OElig"];
        [_entities setObject:@"\u0153" forKey:@"oelig"];
        [_entities setObject:@"\u0160" forKey:@"Scaron"];
        [_entities setObject:@"\u0161" forKey:@"scaron"];
        [_entities setObject:@"\u0178" forKey:@"Yuml"];
        [_entities setObject:@"\u02C6" forKey:@"circ"];
        [_entities setObject:@"\u02DC" forKey:@"tilde"];
        [_entities setObject:@"\u2002" forKey:@"ensp"];
        [_entities setObject:@"\u2003" forKey:@"emsp"];
        [_entities setObject:@"\u2009" forKey:@"thinsp"];
        [_entities setObject:@"\u200C" forKey:@"zwnj"];
        [_entities setObject:@"\u200D" forKey:@"zwj"];
        [_entities setObject:@"\u200E" forKey:@"lrm"];
        [_entities setObject:@"\u200F" forKey:@"rlm"];
        [_entities setObject:@"\u2013" forKey:@"ndash"];
        [_entities setObject:@"\u2014" forKey:@"mdash"];
        [_entities setObject:@"\u2018" forKey:@"lsquo"];
        [_entities setObject:@"\u2019" forKey:@"rsquo"];
        [_entities setObject:@"\u201A" forKey:@"sbquo"];
        [_entities setObject:@"\u201C" forKey:@"ldquo"];
        [_entities setObject:@"\u201D" forKey:@"rdquo"];
        [_entities setObject:@"\u201E" forKey:@"bdquo"];
        [_entities setObject:@"\u2020" forKey:@"dagger"];
        [_entities setObject:@"\u2021" forKey:@"Dagger"];
        [_entities setObject:@"\u2030" forKey:@"permil"];
        [_entities setObject:@"\u2039" forKey:@"lsaquo"];
        [_entities setObject:@"\u203A" forKey:@"rsaquo"];
        [_entities setObject:@"\u20AC" forKey:@"euro"];
    }
    
    if ([string rangeOfString:@"&"].location != NSNotFound)
    {
        NSMutableString* entityBuilder = [NSMutableString string];
        NSMutableString* outputBuilder = [NSMutableString string];
        NSInteger length = [string length];
        // 0 -> nothing
        // 1 -> right after '&'
        // 2 -> between '&' and ';' but no '#'
        // 3 -> '#' found after '&' and getting numbers
        int state = 0;
        int number = 0;
        BOOL trailingDigits = NO;

        for (int i = 0; i < length; i++)
        {
            unichar c = [string characterAtIndex:i];
            if (state == 0)
            {
                if (c == '&')
                {
                    [entityBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                    state = 1;
                }
                else
                {
                    [outputBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                }
                continue;
            }
     
            if (c == '&') 
            {
                state = 1;
                if (trailingDigits)
                {
                    [entityBuilder appendString:[[NSNumber numberWithInt:number] stringValue]];
                    trailingDigits = NO;
                }

                [outputBuilder appendString:entityBuilder];
                [entityBuilder setString:@""];
                [entityBuilder appendString:@"&"];
                continue;
            }

            if (state == 1)
            {
                if (c == ';')
                {
                    state = 0;
                    [outputBuilder appendString:[NSString stringWithString:entityBuilder]];
                    [outputBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                    [entityBuilder setString:@""];
                }
                else
                {
                    number = 0;
                    state = (c != '#') ? 2 : 3;
                    [entityBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                }
            }
            else if (state == 2) 
            {
                [entityBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                if (c == ';') 
                {
                    NSString* entity = [NSString stringWithString:entityBuilder];
                    if ([entity length] > 1)
                    {
                        NSString* key = [entity substringFromIndex:1];
                        key = [key substringToIndex:[key length] - 1];
                        if ([_entities objectForKey:key])
                        {
                            entity = [_entities objectForKey:key];
                        }
                    }

                    [outputBuilder appendString:entity];
                    state = 0;
                    [entityBuilder setString:@""];
                }
            }
            else if (state == 3)
            {
                if (c == ';')
                {
                    if (number > 65535) 
                    {
                        [outputBuilder appendFormat:@"&#%@;", [[NSNumber numberWithInt:number] stringValue]];
                    } 
                    else 
                    {
                        unichar n = (unichar) number;
                        [outputBuilder appendString:[NSString stringWithCharacters:&n length:1]];
                    }
                    state = 0;
                    [entityBuilder setString:@""];
                    trailingDigits = NO;
                } 
                else if (c >= '0' && c <= '9')
                {
                    number = number * 10 + ((int) c - '0');
                    trailingDigits = YES;
                } 
                else 
                {
                    state = 2;
                    if (trailingDigits) 
                    {
                        [entityBuilder appendString:[[NSNumber numberWithInt:number] stringValue]];
                        trailingDigits = NO;
                    }
                    [entityBuilder appendString:[NSString stringWithCharacters:&c length:1]];
                }
            }
        }

        if ([entityBuilder length] > 0)
        {
            [outputBuilder appendString:entityBuilder];
        } 
        else if (trailingDigits)
        {
            [outputBuilder appendString:[[NSNumber numberWithInt:number] stringValue]];
        }

        string = outputBuilder;
    }
    return string;
}

+ (NSString*) urlEncode:(NSString*)string
{
   	NSString* encoded = (NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef) string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return [encoded autorelease]; 
}

+ (NSString*) urlDecode:(NSString*)string
{
    return [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*) stripHtmlTags:(NSString*)string
{
    NSMutableString* builder = [[NSMutableString alloc] initWithCapacity:[string length]];
    NSInteger index = -1;

    for (int i = 0; i < [string length]; i++)
    {
        unichar c = [string characterAtIndex:i];
        if (c == '<')
        {
            index = i;
        }
        else if (c == '>')
        {
            index = -1;
        }
        else if ((index == -1) && (c != '\n'))
        {
            [builder appendString:[NSString stringWithCharacters:&c length:1]];
        }
    }
    
    // Missing close tag
    if (index != -1)
    {
        [builder appendString:[string substringFromIndex:index]];
    }

    return [builder autorelease];
}

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

+ (NSString*) base64Encode:(NSData*)data
{
    NSUInteger length = [data length];
    const UInt8* p = [data bytes];
    
    NSMutableString* string = [[NSMutableString alloc] init];                            
    char buffer[5];
    
    while (length >= 3)
    {
        buffer[0] = base64EncodingTable[p[0] >> 2];
        buffer[1] = base64EncodingTable[((p[0] << 4) & 0x30) | (p[1] >> 4)];
        buffer[2] = base64EncodingTable[((p[1] << 2) & 0x3c) | (p[2] >> 6)];
        buffer[3] = base64EncodingTable[p[2] & 0x3f];
        buffer[4] = 0x00;
        [string appendString:[NSString stringWithCString:buffer encoding:NSASCIIStringEncoding]];
        p += 3;
        length -= 3;
    }
    
    if (length > 0)
    {
        char fragment = (p[0] << 4) & 0x30;
        if (length > 1) 
        {
            fragment |= p[1] >> 4;
        }
        buffer[0] = base64EncodingTable[p[0] >> 2];
        buffer[1] = base64EncodingTable[(int) fragment];
        buffer[2] = (length < 2) ? '=' : base64EncodingTable[(p[1] << 2) & 0x3c];
        buffer[3] = '=';
        buffer[4] = 00;
        [string appendString:[NSString stringWithCString:buffer encoding:NSASCIIStringEncoding]];
    }
    
    return [string autorelease];
}

+ (NSError*) errorForHttpStatusCode:(NSInteger)statusCode;
{
    NSString* message = @"";
    switch (statusCode)
    {
        default: message = [NSString stringWithFormat:@"%d %@", statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]]; break;
    }
    return [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
}

+ (NSDictionary*) parseUrlParameters:(NSString*)string afterSeparator:(NSString*)separator
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    if (separator.length > 0)
    {
        NSArray* parts = [string componentsSeparatedByString:separator];
        if ([parts count] == 2)
        {
            string = [parts objectAtIndex:1];
        }
    }

    for (NSString* property in [string componentsSeparatedByString:@"&"])
    {
        NSArray* nameValue = [property componentsSeparatedByString:@"="];
        if ([nameValue count] == 2)
        {
            [parameters setObject:[WebUtility urlDecode:[nameValue objectAtIndex:1]] forKey:[nameValue objectAtIndex:0]];
        }
    }
    
    return parameters;
}

@end
