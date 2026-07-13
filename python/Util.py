import codecs

def file_contents(fileName:str, encoding:str, errors:str='strict'):
    # read binary to avoid line ending conversion
    with open(fileName, 'rb') as file:
        bytes = file.read()
        return codecs.decode(bytes, encoding, errors)
