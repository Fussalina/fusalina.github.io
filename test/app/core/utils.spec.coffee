describe 'Utility library', ->
  utils = require '../../../app/core/utils'

  describe 'translatejs2cpp(jsCode, fullCode)', ->
    describe 'do not add int main if fullCode set false', ->
      it 'if there is no patten need translate', ->
        expect(utils.translatejs2cpp('hero.moveRight()', false)).toBe('hero.moveRight()')
      it 'if there is var x or var y', ->
        expect(utils.translatejs2cpp('var x = 2;\nvar y = 3', false)).toBe('float x = 2;\nfloat y = 3')
      it 'if there is ===/!==', ->
        expect(utils.translatejs2cpp('if (a === 2 && b !== 1)', false)).toBe('if (a == 2 && b != 1)')
      it 'if there is other var', ->
        expect(utils.translatejs2cpp('var enemy = hero...', false)).toBe('auto enemy = hero...')
      it 'if there is a function definition', ->
        expect(utils.translatejs2cpp('function a() {}\n', false)).toBe('auto a() {}\n')
      it 'if ther is a comment in if..else..', ->
        expect(utils.translatejs2cpp('if(a){\n}\n//test\nelse{\n}', false)).toBe('if(a){\n}\nelse{\n//test\n}')

    describe 'add int main if fullCode set true', ->
      it 'if there is no patten need translate', ->
        expect(utils.translatejs2cpp('hero.moveRight();')).toBe('int main() {\n    hero.moveRight();\nreturn 0;\n}')
      it 'if there is var x or var y', ->
        expect(utils.translatejs2cpp('var x = 2;\nvar y = 3;')).toBe('int main() {\n    float x = 2;\n    float y = 3;\nreturn 0;\n}')
      it 'if there is ===/!==', ->
        expect(utils.translatejs2cpp('while (a === 2 && b !== 1)')).toBe('int main() {\n    while (a == 2 && b != 1)\nreturn 0;\n}')
      it 'if there is other var', ->
        expect(utils.translatejs2cpp('var enemy = hero...')).toBe('int main() {\n    auto enemy = hero...\nreturn 0;\n}')
      it 'if there is a function definition', ->
        expect(utils.translatejs2cpp('function a() {}\n')).toBe('auto a() {}\nint main() {\n    \nreturn 0;\n}')
      it 'if there is a function definition with parameter', ->
        expect(utils.translatejs2cpp('function a(b) {}\n')).toBe('auto a(auto b) {}\nint main() {\n    \nreturn 0;\n}')
      it 'if there is a function definition with parameters', ->
        expect(utils.translatejs2cpp('function a(b, c) {}\na();')).toBe('auto a(auto b, auto c) {}\nint main() {\n    a();\nreturn 0;\n}')

    describe 'if there are start comments', ->
      it 'if there is no code', ->
        expect(utils.translatejs2cpp('//abc\n//def\n')).toBe('//abc\n//def\nint main() {\n    \nreturn 0;\n}')
      it 'if there is code without function definition', ->
        expect(utils.translatejs2cpp('//abc\nhero.moveRight()')).toBe('//abc\nint main() {\n    hero.moveRight()\nreturn 0;\n}')
      it 'if there is code with function definition', ->
        expect(utils.translatejs2cpp('//abc\nfunction a(b, c) {}\nhero.moveRight()')).toBe('//abc\nauto a(auto b, auto c) {}\nint main() {\n    hero.moveRight()\nreturn 0;\n}')

  describe 'getQueryVariable(param, defaultValue)', ->
    beforeEach ->
      spyOn(utils, 'getDocumentSearchString').and.returnValue(
        '?key=value&bool1=false&bool2=true&email=test%40email.com'
      )

    it 'returns the query parameter', ->
      expect(utils.getQueryVariable('key')).toBe('value')

    it 'returns Boolean types if the value is "true" or "false"', ->
      expect(utils.getQueryVariable('bool1')).toBe(false)
      expect(utils.getQueryVariable('bool2')).toBe(true)

    it 'decodes encoded strings', ->
      expect(utils.getQueryVariable('email')).toBe('test@email.com')

    it 'returns the given default value if the key is not present', ->
      expect(utils.getQueryVariable('key', 'other-value')).toBe('value')
      expect(utils.getQueryVariable('NaN', 'other-value')).toBe('other-value')

  describe 'i18n', ->
    beforeEach ->
      this.fixture1 =
        'text': 'G\'day, Wizard! Come to practice? Well, let\'s get started...'
        'blurb': 'G\'day'
        'i18n':
          'es-419':
            'text': '??Buenas, Hechicero! ??Vienes a practicar? Bueno, empecemos...'
          'es-ES':
            'text': '??Buenas Mago! ??Vienes a practicar? Bien, empecemos...'
          'es':
            'text': '??Buenas Mago! ??Vienes a practicar? Muy bien, empecemos...'
          'fr':
            'text': 'S\'lut, Magicien! Venu pratiquer? Ok, bien d??butons...'
          'pt-BR':
            'text': 'Bom dia, feiticeiro! Veio praticar? Ent??o vamos come??ar...'
          'en':
            'text': 'Ohai Magician!'
          'de':
            'text': '\'N Tach auch, Zauberer! Kommst Du zum ??ben? Dann lass uns anfangen...'
          'sv':
            'text': 'Godagens, trollkarl! Kommit f??r att ??va? N??, l??t oss b??rja...'

    it 'i18n should find a valid target string', ->
      expect(utils.i18n(this.fixture1, 'text', 'sv')).toEqual(this.fixture1.i18n['sv'].text)
      expect(utils.i18n(this.fixture1, 'text', 'es-ES')).toEqual(this.fixture1.i18n['es-ES'].text)

    it 'i18n picks the correct fallback for a specific language', ->
      expect(utils.i18n(this.fixture1, 'text', 'fr-be')).toEqual(this.fixture1.i18n['fr'].text)

    it 'i18n picks the correct fallback', ->
      expect(utils.i18n(this.fixture1, 'text', 'nl')).toEqual(this.fixture1.i18n['en'].text)
      expect(utils.i18n(this.fixture1, 'text', 'nl', 'de')).toEqual(this.fixture1.i18n['de'].text)

    it 'i18n falls back to the default text, even for other targets (like blurb)', ->
      delete this.fixture1.i18n['en']
      expect(utils.i18n(this.fixture1, 'text', 'en')).toEqual(this.fixture1.text)
      expect(utils.i18n(this.fixture1, 'blurb', 'en')).toEqual(this.fixture1.blurb)
      delete this.fixture1.blurb
      expect(utils.i18n(this.fixture1, 'blurb', 'en')).toEqual(null)

    it 'i18n can fall forward if a general language is not found', ->
      expect(utils.i18n(this.fixture1, 'text', 'pt')).toEqual(this.fixture1.i18n['pt-BR'].text)

  describe 'inEU', ->
    it 'EU countries return true', ->
      euCountries = ['Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'United Kingdom']
      try
        euCountries.forEach((c) -> expect(utils.inEU(c)).toEqual(true))
      catch err
        # NOTE: without try/catch, exceptions do not yield failed tests.
        # E.g. utils.inEU used to call Array.find which isn't supported in IE11, try/catch required to register test fail
        expect(err).not.toBeDefined()
    it 'non-EU countries return false', ->
      nonEuCountries = ['united-states', 'peru', 'vietnam']
      try
        nonEuCountries.forEach((c) -> expect(utils.inEU(c)).toEqual(false))
      catch err
        expect(err).not.toBeDefined()

  describe 'ageOfConsent', ->
    it 'US is 13', ->
      expect(utils.ageOfConsent('united-states')).toEqual(13)
    it 'Latvia is 13', ->
      expect(utils.ageOfConsent('latvia')).toEqual(13)
    it 'Austria is 14', ->
      expect(utils.ageOfConsent('austria')).toEqual(14)
    it 'Greece is 15', ->
      expect(utils.ageOfConsent('greece')).toEqual(15)
    it 'Slovakia is 16', ->
      expect(utils.ageOfConsent('slovakia')).toEqual(16)
    it 'default for EU countries 16', ->
      expect(utils.ageOfConsent('israel')).toEqual(16)
    it 'default for other countries is 0', ->
      expect(utils.ageOfConsent('hong-kong')).toEqual(0)
    it 'default for unknown countries is 0', ->
      expect(utils.ageOfConsent('codecombat')).toEqual(0)
    it 'default for undefined countries is 0', ->
      expect(utils.ageOfConsent(undefined)).toEqual(0)
    it 'defaultIfUnknown works', ->
      expect(utils.ageOfConsent(undefined, 13)).toEqual(13)

  describe 'createLevelNumberMap', ->
    # r=required p=practice
    it 'returns correct map for r', ->
      levels = [
        {key: 1, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1'])
    it 'returns correct map for r r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '2'])
    it 'returns correct map for p', ->
      levels = [
        {key: 1, practice: true}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['0a'])
    it 'returns correct map for r p r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '2'])
    it 'returns correct map for r p p p', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: true}
        {key: 4, practice: true}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '1b', '1c'])
    it 'returns correct map for r p p p r p p r r p r', ->
      levels = [
        {key: 1, practice: false}
        {key: 2, practice: true}
        {key: 3, practice: true}
        {key: 4, practice: true}
        {key: 5, practice: false}
        {key: 6, practice: true}
        {key: 7, practice: true}
        {key: 8, practice: false}
        {key: 9, practice: false}
        {key: 10, practice: true}
        {key: 11, practice: false}
      ]
      levelNumberMap = utils.createLevelNumberMap(levels)
      expect((val.toString() for key, val of levelNumberMap)).toEqual(['1', '1a', '1b', '1c', '2', '2a', '2b', '3', '4', '4a', '5'])

  describe 'findNextLevel and findNextAssessmentForLevel', ->
    # r=required p=practice c=complete *=current a=assessment l=locked
    # utils.findNextLevel returns next level 0-based index
    # utils.findNextAssessmentForLevel returns next level 0-based index

    # Find next available incomplete level, depending on whether practice is needed
    # Find assessment level immediately after current level (and its practice levels)
    # Only return assessment if it's the next level
    # Skip over practice levels unless practice neeeded
    # levels = [{practice: true/false, complete: true/false, assessment: true/false}]

    describe 'when no practice needed', ->
      needsPractice = false
      it 'returns correct next levels when rc* p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when pc* p r', ->
        levels = [
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when pc* p p', ->
        levels = [
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc* p rc', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc rc* a r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: false, assessment: true}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(4)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(3)
      it 'returns correct next levels when rc* r p p p a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc* p p p a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 1, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 1, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc* p p a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc pc pc* a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc pc pc ac* r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 5, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 5, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc ac rc* p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 6, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 6, needsPractice)).toEqual(10)
      it 'returns correct next levels when rc rc* p p p a rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc pc pc* a rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc* p p p ac rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc* a rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc* rcl p r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true, locked: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 1, needsPractice)).toEqual(-1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)

    describe 'when needs practice', ->
      needsPractice = true
      it 'returns correct next levels when rc* p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc* rc', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc p rc*', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(1)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc*', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc rc* a r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: false, assessment: true}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(4)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(3)
      it 'returns correct next levels when rc pc p rc* p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(4)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc* pc', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc* pc p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc* pc r', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        expect(utils.findNextAssessmentForLevel(levels, 3)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc* pc p r', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(5)
        expect(utils.findNextAssessmentForLevel(levels, 3)).toEqual(-1)
      it 'returns correct next levels when rc pc pc rc* r p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(4)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc* pc rc', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: false, complete: true}
        ]
        expect(utils.findNextLevel(levels, 0, needsPractice)).toEqual(3)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p rc* r p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 3, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p a rc* r p', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false, assessment: true}
          {practice: false, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc pc p a rc* pc p r', ->
        levels = [
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc* p p p a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 1, needsPractice)).toEqual(2)
        expect(utils.findNextAssessmentForLevel(levels, 1, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc* p p a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(3)
        expect(utils.findNextAssessmentForLevel(levels, 2, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc* a r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc pc pc ac* r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 5, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 5, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc ac rc* p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 6, needsPractice)).toEqual(7)
        expect(utils.findNextAssessmentForLevel(levels, 6, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc* ac rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(7)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc* a rc p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: false}
          {practice: false, complete: true}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(7)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(5)
      it 'returns correct next levels when rc rc pc pc pc* ac rc pc pc pc a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 4, needsPractice)).toEqual(11)
        expect(utils.findNextAssessmentForLevel(levels, 4, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc pc pc pc ac* r p p p a r r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {practice: true, complete: true}
          {assessment: true, complete: true}
          {practice: false, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {practice: true, complete: false}
          {assessment: true, complete: false}
          {practice: false, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 5, needsPractice)).toEqual(6)
        expect(utils.findNextAssessmentForLevel(levels, 5, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc* rcl p r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true, locked: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 1, needsPractice)).toEqual(-1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc rcl* p r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true, locked: true}
          {practice: true, complete: false}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 2, needsPractice)).toEqual(-1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)
      it 'returns correct next levels when rc rc rcl pc* r', ->
        levels = [
          {practice: false, complete: true}
          {practice: false, complete: true}
          {practice: false, complete: true, locked: true}
          {practice: true, complete: true}
          {practice: false, complete: false}
        ]
        expect(utils.findNextLevel(levels, 3, needsPractice)).toEqual(-1)
        expect(utils.findNextAssessmentForLevel(levels, 0, needsPractice)).toEqual(-1)

