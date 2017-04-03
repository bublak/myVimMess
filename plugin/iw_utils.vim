" Make sure we run only once
"if exists("loaded_iwUtils")
    "finish
"endif

if !has('python3')
    echo "Error: Required vim compiled with +python"
    finish
endif

let loaded_iwUtils = 1

"           =================function====================
" get from Require.js fclient definitions and file locations, and get to file according search definition
" -> where was the cursor
function! IwMoveFclientFile(searchFclientWord)
python3 <<EOF
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
python3 <<EOF
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
"move to unit test
function! IwGetUnitTestFile()
python3 <<EOF
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

" SOME functionality cuts
"zmeni radek 0 v aktualnim souboru na neco
"vim.current.buffer[0] = 10*"-"

