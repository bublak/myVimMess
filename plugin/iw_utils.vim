" Make sure we run only once
"if exists("loaded_iwUtils")
    "finish
"endif

if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

let loaded_iwUtils = 1

"           =================function====================
" get from Require.js fclient definitions and file locations, and get to file according search definition
" -> where was the cursor
function! IwMoveFclientFile(searchFclientWord)
python <<EOF
import vim

name = vim.current.buffer.name

if name[-3:] != '.js':
    print '        NENI JS FILE'
    vim.command('return -1')
    #TODO = jak zde vyskocit, aby program nepokracoval

searchWord = vim.eval("a:searchFclientWord") 

lines       = vim.current.buffer
linesNumber = len(lines)
startLine   = 0 # start line to iterate

i = 0
for i in range(0,linesNumber):
    if 'define' in lines[i]:
        startLine = i #move to file lines
        break

requireFiles = '' # require files are without .js extension
requireDefinitions = '' # how are defined in code

i = 0
for i in range(startLine,linesNumber):
    requireFiles += lines[i]
    if '],' in requireFiles:
        startLine = i #move to definitions line
        break;

for i in range(startLine,linesNumber):
    requireDefinitions += lines[i]
    if ')' in requireDefinitions: #end for definitions
        break

#get only files inside the brackets []
requireFiles = requireFiles[requireFiles.find('[')+1:requireFiles.find(']')] 
#cut the apostrophes and whitespaces
requireFiles = requireFiles.replace(' ', '') #change whitespaces
requireFiles = requireFiles.replace('\'', '') #apostrphes

#get only definitions inside, which are between brackets ()
requireDefinitions = requireDefinitions[requireDefinitions.find('(')+1:requireDefinitions.find(')')] 
requireDefinitions = requireDefinitions.replace(' ', '')

# get sets from string
setRequireFiles = requireFiles.split(',')
setRequireDefinitions = requireDefinitions.split(',')

if '' in setRequireDefinitions:
    setRequireDefinitions.remove('');

if '' in setRequireFiles:
    setRequireFiles.remove('');

fclientFile = ''

if len(setRequireDefinitions):
    #find the searchWord in definitions, and get the file for it
    fclientFile = setRequireFiles[setRequireDefinitions.index(searchWord)]
elif len(setRequireFiles):
    # if there are no requireDefinitions, try to find some file, containing the searchWord
    searchWord = searchWord.lower()

    #setRequireFiles.reverse() # reverse, because trying to find more specific file ( - only idea)
    for i in range(0, len(setRequireFiles)):
        if searchWord in setRequireFiles[i]:
            print 'aaaaa'
            if 'backbone' in setRequireFiles[i]:
                print 'path with backbone is not supported'
                continue

            fclientFile = setRequireFiles[i]
            break

if fclientFile:
    fclientFile = 'portal/fclient/' + fclientFile + '.js'

    print fclientFile
    commandToRun = 'e ' + fclientFile
    vim.command(commandToRun)

#TODO po vyhledani a skoceni na soubor, posunout se za uvodni komentare
#TODO test na existenci souboru

EOF
endfunction

"           =================function====================
" move to rest adapter  => if the cursor is on the function word, then go to this word in adapter file
" This function exptects the created 'tag' file, and loaded, because it use it to find adapter class.
function! IwMoveToRestAdapterFile(searchFunctionWord)
python <<EOF
import vim

searchWord = vim.eval("a:searchFunctionWord") 

lines       = vim.current.buffer
linesNumber = len(lines)
adapterFile = ''

i = 0
#TODO not work, if there are two adapters defined = because it search only the first one
for i in range(0,linesNumber):
    if '\'IW_Remoteapi_Rest_Adapters' in lines[i]:
        adapterFile = lines[i]
        break

if adapterFile:
    firstQuotePosition = adapterFile.find('\'') + 1;
    
    adapterFile = adapterFile[firstQuotePosition:]
    secondQuotePosition = adapterFile.find('\'')
    adapterFile = adapterFile[:secondQuotePosition]

    commandToRun = 'tag ' + adapterFile
    vim.command(commandToRun)

    if (searchWord):
        vim.command('/'+searchWord)

EOF
endfunction

"           =================function==================== 
"move in IW namespaces -> you should call, after you find the namespace "use" line
" This function exptects the created 'tag' file, and loaded, because it use it to find class.
function! IwMoveNamespaces()
python <<EOF
import vim

line = vim.current.line

#cut off: ' as KVA;' part
#note: if there is not ' as ' -> the -1 value is returned, which caused cutting the ; at the end of line!!!
line = line[:line.find(' as ')] 

#cut off "use "
line = line[4:]

if line.find("_") > -1:   #if no namespace use, go directly to class
    vim.command('tag /'+line);
elif line.find("\\") > -1:
    line = line.replace('\\', '/') #change path separators
    module = line[3:len(line)]
    module = module[:module.find('/')]
    module = module.lower()
    line = 'e ./portal/' + module + '/impl/' + line + '.php'
    vim.command(line)

EOF
endfunction

"           =================function====================
"move to unit test
function! IwGetUnitTestFile()
python <<EOF
import vim

filename = vim.current.buffer.name

#testFilename = filename[:filename.find('/portal/')] 
#change portal for portal_test
#print testFilename + '/portal_test' + filename[len(testFilename)+7:]
#or
testFilename = filename.replace('/portal/', '/portal_test/unit/')
testFilename = testFilename.replace('.php', 'Test.php')

vim.command('e '+testFilename);

EOF
endfunction

"move to class file
"
" This function exptects the created 'tag' file, and loaded, because it use it to find class.
function! IwGetClassFile(sCls, lineNumber)

python <<EOF
import vim
import re

lines = vim.current.buffer

# TODO NOT USED anymore
def searchWordWithEqualSign(lines, sCls, lineNumber):

    sCls = sCls.strip()
    #print 'received data:'
    #print sCls
    #print lineNumber

    result = sCls


    #linesNumber = len(lines)
    linesNumber = lineNumber

    i = 0
    for i in range(linesNumber, 0, -1):
        #print i
        #print lines[i]
        #print sCls
        #print lines[i].find(sCls)

        if lines[i].find(sCls) > -1:
            #print 'uvnitr'
            line = lines[i]

            if line.find("\\") > -1:
                #print 'a:';
                #namespace
                
                if line.find(" as ") > -1:
                    #This if is for lines like:
                    # use IW\Core\ListView\Service;
                    # use IW\Core\ListView\Category\Service as CategoryService;
                    # -- and we search Service   So the code is prevent for opening wrong Category/Service
                    part = line[line.find(' as ')+4:-1]
                    if part == sCls:
                        result = _getNamespacedClass(line)
                    else:
                        continue
                else:
                    result = _getNamespacedClass(line)

                break
            elif line.find("IW_Core_BeanFactory::singleton") > -1:
                #print 'b:';
                line = line[(line.find('singleton')+11):]
                line = line[:(line.find('\')')):]

                result = 'tag /' + line
                break
            elif line.find("getInstance") > -1:
                #print 'c:';
                #'$kuku = AHOJabcd::getInstance();';
                line = line[line.find('= ')+2:]
                line = line[:line.find('::getI')]

                #print line
                result = start(lines, line, i-1)
                break
            elif line.find("new ") > -1:
                #print 'd:';
                #'$fvur = new Kabcd();';
                line = line[line.find('new ')+4:]
                line = line[:line.find('()')]
                
                result = start(lines, line, i-1)
                break
            elif line.find("(new ") > -1:
                #print 'e:';
                line = line[line.find('(new ')+4:]
                line = line[:line.find('())')]

                result = start(lines, line, i-1)
                break
            elif line.find("_") > -1:
                #print 'f:';
                result = 'tag /' + sCls
                break
            else:
                #print 'nothing found'
                #TODO - if nothing found, try open namespace xxxxx;
                a = sCls

    #print 'koncim s:'
    #print result
    return result

def _getNamespacedClass(line):
    #note: if there is not ' as ' -> the -1 value is returned, which caused cutting the ; at the end of line!!!
    line = line[:line.find(' as ')] 

    #cut off "use "
    line = line[4:]

    line = line.replace('\\', '/') #change path separators

    module = line[3:len(line)]
    module = module[:module.find('/')]
    module = module.lower()

    line = 'e ./portal/' + module + '/impl/' + line + '.php'

    return line

# return true, if word is followed by '=' like this:  xxx = something .. word 
def hasEqualSignBeforeWord(line, word):
    equalSingIndex = line.find('=');
    
    if equalSingIndex > -1:
        equalSingIndexB = line.find('=', equalSingIndex + 1, equalSingIndex + 2); # get second '=', to check 'if statement' '=='

        if equalSingIndexB < 0:
            wordIndex = line.find(word);

            if wordIndex > equalSingIndex:
                return True


    return False

def startSearching(word, lines, lineNumber):

    line = lines[lineNumber]

    result = isWordOldClass(word, line)

    if result != False:
        printd('is old class def')
        return result

    result = getKnownDefinitions(word, lines, lineNumber)

    #if hasEqualSignBeforeWord(lines[lineNumber], searchWord):
    #searchWordWithEqualSign(lines, searchWord, lineNumber)
    #else:
    #searchWordWithoutEqualSign(lines, searchWord, lineNumber)

    return result

def isWordOldClass(word, line):
    pattern = '_.*_'
    if re.search(pattern, word):
        return getTagForWord(word)

    return False

# search backwards from lineNumber, until the search word or word 'function' is find, if no definition and function found,
# search from begin of file
def getVariable(word, lines, lineNumber):

    printd('je to variable')

    foundedLine = False 
    result      = False
    hasFunction = False

    i = 0
    for i in range(lineNumber, 0, -1):
        line = lines[i]

        patternWord = word + ' *='
        if re.search(patternWord, line):
            printd('slovo nalezeno, radka: ' + line)
            foundedLine = line
            break

        patternFunction = ' *function ';  # handle constructor (skip it)

        if re.search(patternFunction, line):
            hasFunction = True
            break;

    if hasFunction == True:
        printd('byla funkce, hledam od zacatku')
        i = 0
        for i in range(0, lineNumber):
            line = lines[i]

            patternWord = word + ' *='
            if re.search(patternWord, line):
                foundedLine = line
                break

    printd(foundedLine)

    if foundedLine != False:
        printd('nalezena variable na radce: ' + i.__str__())
        printd(' radka: ' + line)
        result = processLineForClassDefinition(word, lines, line, i)

    return result

def processLineForClassDefinition(word, lines, line, lineNumber):
        
    restOfLine = line.split('=', 1)[1].strip()

    printd(restOfLine)

    pattern = '(.*)::getInstance\(\)'

    printd('pattern: ' + pattern)
    res = re.search(pattern, restOfLine)
    if res:
        newWord = res.groups()[0]
        printd('hledane nove slovo: ' + newWord)
        return getUseNamespacedWord(newWord, lines, lineNumber)

    quotes = '(\'|")'
    pattern = 'IW_Core_BeanFactory::singleton\(' + quotes + '(.*)' + quotes + '\)';
    printd('pattern: ' + pattern)
    res = re.search(pattern, restOfLine)
    if res:
        newWord = res.groups()[0]
        printd('hledane nove slovo: ' + newWord)
        return getTagForWord(newWord)

    pattern = 'new (.*)\('; #pridat bily znaky pred zavorku, a aby nebyl zravej

    printd('pattern: ' + pattern)
    res = re.search(pattern, restOfLine)
    if res:
        newWord = res.groups()[0]
        printd('hledane nove slovo: ' + newWord)
        return getUseNamespacedWord(newWord, lines, lineNumber)

    #TODO implement all other types :)
    # x) tohle nejde: (protoze otevre ba, misto hledanyho aaa: $aaa  = $ba->getAAAById($aaId);
    # x) tohle nevim jestli ma cenu: function definition, like:   $neco = $this->getDef();
    return False
    

def getKnownDefinitions(word, lines, lineNumber):
    line = lines[lineNumber]
    printd('hledane slovo: ' + word + '; A radka: ')
    printd(line)

    quotes = '(\'|")'

    pattern = '\$' + word;

    printd(pattern);
    if re.search(pattern, line):
        printd('variable A')
        return getVariable(word, lines, lineNumber)

    pattern = '->' + word;

    printd(pattern);
    if re.search(pattern, line):
        printd('variable B')
        return getVariable(word, lines, lineNumber)

    #$orgService = IW_Core_BeanFactory::singleton('IW_OrgStr_User_Service')
    pattern = 'IW_Core_BeanFactory::singleton\(' + quotes + word + quotes + '\)';

    printd(pattern);
    if re.search(pattern, line):
        printd('beanfactory singleton')
        return getTagForWord(word)

    #new Word()
    # ->valid(new VoValidator(), $listViewVo, 'listViewVo')
    #throw new IW_Core_Authorization_Exception(
    pattern = 'new ' + word + '\('; #pridat bily znaky pred zavorku, a aby nebyl zravej

    printd(pattern);
    if re.search(pattern, line):
        printd('new word')
        return getUseNamespacedWord(word, lines, lineNumber)

    # NOT this -> IW_Core_Validate::getInstance() -> this is catched before with  isWordOldClass(word, line)
    # but this-> Service::getInstance()
    pattern = word + '::getInstance\('; #pridat bily znaky pred zavorku, a aby nebyl zravej

    printd(pattern);
    printd(re.search(pattern, line));
    if re.search(pattern, line):
        printd('word::getinstance')
        return getUseNamespacedWord(word, lines, lineNumber)

    #use \Brum\Vrum\Rum as Word;
    pattern = 'use .*as ' + word; #pridat zacatek radku

    printd(pattern);
    if re.search(pattern, line):
        printd('use as word')
        return getUseNamespacedWordFromLine(word, lines, lineNumber)
    
    #use \Brum\Vrum\Word;
    #use \Brum\Vrum\Word as Rum;
    pattern = 'use .*' + word + '(;| )';  #pridat zacatek radku

    printd(pattern);
    if re.search(pattern, line):
        printd('use word')
        return getUseNamespacedWordFromLine(word, lines, lineNumber)

    printd('koncim, nic jsem nenasel')
    return False

def getTagForWord(word):
    return 'tag /' + word

def getUseNamespacedWordFromLine(word, lines, lineNumber):
    line = lines[lineNumber]

    return _getNamespacedClass(line)

def getUseNamespacedWord(word, lines, lineNumber):

    result = False
    i = 0

    for i in range(0, lineNumber):
        printd(i)
        printd(lines[i])
        printd(word)
        printd(lines[i].find(word))

        line = lines[i]

        if line.find("{") > -1: # namespace definitions ends with class {
            break
        else:
            endWord = word + ';'

            if lines[i].find(endWord) > -1:
                printd('uvnitr')

                if line.find(" as ") > -1:
                    #This if is for lines like:
                    # use IW\Core\ListView\Service;
                    # use IW\Core\ListView\Category\Service as CategoryService;
                    # -- and we search Service   So the code is prevent for opening wrong Category/Service
                    part = line[line.find(' as ')+4:-1]
                    if part == word:
                        result = _getNamespacedClass(line)
                    else:
                        continue
                else:
                    result = _getNamespacedClass(line)

                break

    printd('nasel jsem: ' + result)
    return result
 
#def printd(string, debug=True):
def printd(string, debug=False):
    if debug == True:
        print(string)
    

searchWord = vim.eval("a:sCls") 
lineNumber = int(vim.eval("a:lineNumber"))

lineNumber = lineNumber - 1 #correction to right line, where is cursor
searchWord = searchWord.strip()
result = startSearching(searchWord, lines, lineNumber)

if result != False:
    vim.command(result)
else:
    print result


EOF
endfunction

" SOME functionality cuts
"zmeni radek 0 v aktualnim souboru na neco
"vim.current.buffer[0] = 10*"-"

