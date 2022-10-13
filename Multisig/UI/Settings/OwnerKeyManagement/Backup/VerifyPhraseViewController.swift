//
//  VerifyPhraseViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Algorithms

class VerifyPhraseViewController: UIViewController {

    // The phrase to verify
    var phrase: [String] = []

    // Generated questions from the phrase
    var questions: [Question] = []

    enum State {
        // after showing this screen
        case initial
        // whenever question is displayed
        case question
        // to check the answer
        case checking
        // when the answer is correct
        case correct
        // when the answer is wrong
        case incorrect
        // when all questions answered correctly
        case completed
    }

    // Models the asked question
    struct Question {
        // index of the word in the `phrase` (0-based)
        var wordNumber: Int
        // expected word at that index
        var correctAnswer: String
        // choices, including correct answer
        var choices: [String]
    }

    // current screen state that determines logical and visual transitions.
    var state: State = .initial {
        didSet {
            didUpdateState(from: oldValue)
        }
    }

    // called when phrase is verified successfully
    var completion: (() -> Void)?

    // parameter for how many questions to generate in total
    var totalQuestions: Int = 3

    // parameter for how many choices to offer per question
    var choicesPerQuestion: Int = 3

    // currently asked question
    var currentQuestion: Int = 0

    // currently selected choice by user
    var currentChoice: Int? = nil

    @IBOutlet weak var titleLabel: UILabel!

    // a view to hold the chosen word
    @IBOutlet weak var selectedWordContainer: UIView!

    @IBOutlet weak var wordNumberLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!

    // container holding alternative answers
    @IBOutlet weak var choiceStackView: UIStackView!

    @IBOutlet weak var errorStackView: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorIcon: UIImageView!

    @IBOutlet weak var restartButton: UIButton!

    // label in the navigation bar
    var pageLabel: UILabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Verify seed phrase"
        titleLabel.text = "Tap on the correct word from your seed phrase."
        wordLabel.text = "Word"
        errorLabel.text = "Incorrect word"

        // we have to set frame explicitly, otherwise the text is automatically ellipsized by the system.
        pageLabel.frame = CGRect(x: 0, y: 0, width: 50, height: 21)
        pageLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: pageLabel)

        pageLabel.setStyle(.calloutTertiary)
        titleLabel.setStyle(.body)
        wordLabel.setStyle(.headline)
        wordNumberLabel.setStyle(.headlineSecondary)
        errorLabel.setStyle(.calloutError)

        restartButton.setText("Restart", .filled)
        // we're taking the system icon here
        let restartIcon = UIImage(
            systemName: "arrow.triangle.2.circlepath",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        restartButton.setImage(restartIcon, for: .normal)

        errorStackView.isHidden = true
        restartButton.isHidden = true
        generateQuesitons()
        currentChoice = nil
        currentQuestion = 0

        state = .question
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.backupConfirmSeedPhrase)
    }

    func set(mnemonic: String) {
        phrase = mnemonic.split(separator: " ").compactMap(String.init)
    }

    // implements actions for transitions in the state machine
    //    |   From    |    To     |                       Action                       |
    //    | --------- | --------- | -------------------------------------------------- |
    //    | initial   | question  | display current question                           |
    //    | question  | checking  | check the selected answer                          |
    //    | checking  | correct   | answer was ok. Move to the next question or finish |
    //    | checking  | incorrect | wrong answer. Only restart possible                |
    //    | incorrect | question  | restart with new questions                         |
    //    | correct   | question  | display the next question                          |
    //    | correct   | completed | finished, call completion                          |
    //
    // All other transitions are prohibited (ignored)
    func didUpdateState(from oldValue: State) {
        switch (oldValue, state) {
        case (.initial, .question):
            currentQuestion = 0
            displayQuestion()

        case (.question, .checking):
            checkAnswer()

        case (.checking, .correct):
            displayCorrect()

        case (.checking, .incorrect):
            displayIncorrect()

        case (.incorrect, .question):
            errorStackView.isHidden = true
            restartButton.isHidden = true
            generateQuesitons()
            currentChoice = nil
            currentQuestion = 0
            displayQuestion()

        case (.correct, .question):
            displayQuestion()

        case (.correct, .completed):
            completion?()

        default:
            // ignore
            break
        }
    }

    func generateQuesitons() {
        // randomly get N words as correct ones
        let correctWords = phrase.randomSample(count: totalQuestions)

        // for each such correct word randomly sample from the remaining words to create
        // alternative answers. Answers must include the correct answer.
        questions = correctWords.map { answer in
            let incorrectAnswers = Set(phrase).subtracting([answer]).randomSample(count: choicesPerQuestion - 1)
            let answers = (incorrectAnswers + [answer]).shuffled()
            return Question(
                wordNumber: phrase.firstIndex(of: answer)!,
                correctAnswer: answer,
                choices: answers)
        }
    }

    func displayQuestion() {
        // make selected word empty
        let emptyWord = createWordView()
        emptyWord.style = .empty
        selectedWordContainer.subviews.first?.removeFromSuperview()
        selectedWordContainer.addSubview(emptyWord)
        selectedWordContainer.wrapAroundView(emptyWord)

        // set the choices to the question's words
        let question = questions[currentQuestion]
        let choices: [WordView] = question.choices.enumerated().map { index, word in
            let view = createWordView()
            view.wordLabel.text = word
            view.style = .normal
            view.didTap = { [weak self] in
                guard let self = self else { return }
                // the index is captured by this block, so every word will know its index when it is tapped.
                self.didSelectWord(at: index)
            }
            return view
        }
        // remove existing words
        for existing in choiceStackView.arrangedSubviews {
            existing.removeFromSuperview()
        }
        // add new choice words
        for view in choices {
            choiceStackView.addArrangedSubview(view)
        }

        // update the word number
        wordNumberLabel.text = "#\(question.wordNumber + 1)"
        // update the page (question) number
        pageLabel.text = "\(currentQuestion + 1) of \(questions.count)"
    }

    func createWordView() -> WordView {
        let word = WordView()
        word.translatesAutoresizingMaskIntoConstraints = false
        word.addConstraints([
            word.widthAnchor.constraint(equalToConstant: 100),
            word.heightAnchor.constraint(equalToConstant: 40)
        ])
        word.wordLabel.text = nil
        return word
    }

    // check answer
    func checkAnswer() {
        // check that selected choice matches correct choice
        if let choice = currentChoice, questions[currentQuestion].choices[choice] == questions[currentQuestion].correctAnswer {
            state = .correct
        } else {
            state = .incorrect
        }
    }

    func displayCorrect() {
        guard let word = selectedWordContainer.subviews.first as? WordView else {
            return
        }
        // show the visual response that the choice is correct
        word.style = .correct

        // delay moving to next question so that user could actually see the 'correct' response and notice it.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.moveToNext()
        }
    }

    func moveToNext() {
        let hasMore = currentQuestion + 1 < questions.count
        if hasMore {
            currentQuestion += 1
            currentChoice = nil
            state = .question
        } else {
            state = .completed
        }
    }

    func displayIncorrect() {
        guard let word = selectedWordContainer.subviews.first as? WordView else {
            return
        }
        // change selected choice style
        word.style = .incorrect

        // show error stack view
        errorStackView.isHidden = false

        // show the restart button
        restartButton.isHidden = false
    }

    func didSelectWord(at newChoice: Int) {
        // only react if we are waiting for answer (question state)
        guard
            state == .question,
            currentChoice == nil,
            newChoice < choiceStackView.arrangedSubviews.count else {
                return
        }

        self.currentChoice = newChoice

        // remove the chosen word from choices
        let wordView = choiceStackView.arrangedSubviews[newChoice]
        choiceStackView.removeArrangedSubview(wordView)

        // set that word to selected view
        selectedWordContainer.subviews.first?.removeFromSuperview()
        selectedWordContainer.addSubview(wordView)
        selectedWordContainer.wrapAroundView(wordView)

        state = .checking
    }

    @IBAction func didTapRestart(_ sender: Any) {
        guard state == .incorrect else { return }
        state = .question
    }
}
