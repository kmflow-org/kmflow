// static/js/quiz.js

document.addEventListener("DOMContentLoaded", function () {
    const correctAnswers = JSON.parse(document.getElementById("correctAnswers").textContent);

    document.getElementById("submitQuiz").addEventListener("click", function () {
        checkAnswers();
    });

    function checkAnswers() {
        let form = document.getElementById('quizForm');
        let results = document.getElementById('results');
        let formData = new FormData(form);
        let allQuestionsCorrect = true;
        let incorrectyAnswered = [];

        correctAnswers.forEach(function (question, index) {
            let selectedOptions = [];
            formData.getAll('question' + index).forEach(val => {
                selectedOptions.push(parseInt(val));
            });

            let correct = question["Answers"].every(val => selectedOptions.includes(val)) &&
                selectedOptions.every(val => question["Answers"].includes(val));

            if (!correct) {                
                incorrectyAnswered.push("<h4> Question " + (index+1) + " is incorrect </h3>");
                allQuestionsCorrect = false;
            }
        });
        results.innerHTML = "";
        if (allQuestionsCorrect) {
            results.innerHTML = "<h2>All correct..Good job!!</h2>"
        } else {
            incorrectyAnswered.forEach(val => results.innerHTML+=val);
        }
    }
});
