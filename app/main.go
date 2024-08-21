package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"gopkg.in/yaml.v2"
)

type Config struct {
	S3Bucket       string `yaml:"s3bucket"`
	Region         string `yaml:"region"`
	ReadFromS3     bool   `yaml:"readFromS3"`
	CheckerService string `yaml:"checkerServiceUrl"`
}

type Quiz struct {
	ID        int        `yaml:"id"`
	Title     string     `yaml:"title"`
	Questions []Question `yaml:"questions"`
}

type Question struct {
	Text    string   `yaml:"text"`
	Type    string   `yaml:"type"`
	Options []string `yaml:"options"`
	Answers []int    `yaml:"answers"`
	Code    string   `yaml:"code,omitempty"` // New field for code snippets
}

var config Config
var quizzes []Quiz
var tmpl *template.Template
var mutex sync.Mutex

// Custom function to add two integers
func add(a, b int) int {
	return a + b
}

func loadConfig() {
	data, err := os.ReadFile("config.yaml")
	if err != nil {
		log.Fatalf("Failed to read config file: %v", err)
	}
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		log.Fatalf("Failed to unmarshal config file: %v", err)
	}
}

func loadQuizzesFromS3() {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(config.Region)},
	)
	if err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}

	svc := s3.New(sess)
	input := &s3.ListObjectsV2Input{
		Bucket: aws.String(config.S3Bucket),
	}

	result, err := svc.ListObjectsV2(input)
	if err != nil {
		log.Fatalf("Unable to list items in bucket %q, %v", config.S3Bucket, err)
	}

	var newQuizzes []Quiz
	for _, item := range result.Contents {
		getObjectInput := &s3.GetObjectInput{
			Bucket: aws.String(config.S3Bucket),
			Key:    aws.String(*item.Key),
		}
		result, err := svc.GetObject(getObjectInput)
		if err != nil {
			log.Fatalf("Unable to download item %q, %v", *item.Key, err)
		}

		body, err := io.ReadAll(result.Body)
		if err != nil {
			log.Fatalf("Failed to read S3 object body: %v", err)
		}

		var quiz Quiz
		err = yaml.Unmarshal(body, &quiz)
		if err != nil {
			log.Fatalf("Failed to unmarshal quiz YAML: %v", err)
		}
		newQuizzes = append(newQuizzes, quiz)
	}
	mutex.Lock()
	quizzes = newQuizzes
	mutex.Unlock()
}

func loadQuizzesFromFileSystem() {
	files, err := os.ReadDir("./quizzes")
	if err != nil {
		log.Fatalf("Failed to read quizzes directory: %v", err)
	}

	var newQuizzes []Quiz
	for _, file := range files {
		filePath := filepath.Join("./quizzes", file.Name())
		data, err := os.ReadFile(filePath)
		if err != nil {
			log.Fatalf("Failed to read quiz file %s: %v", filePath, err)
		}

		var quiz Quiz
		err = yaml.Unmarshal(data, &quiz)
		if err != nil {
			log.Fatalf("Failed to unmarshal quiz YAML: %v", err)
		}
		newQuizzes = append(newQuizzes, quiz)
	}
	mutex.Lock()
	quizzes = newQuizzes
	mutex.Unlock()
}

func handler(w http.ResponseWriter, r *http.Request) {
	reloadQuizzes()
	tmpl := template.Must(template.New("index.html").Funcs(template.FuncMap{
		"add": add,
	}).ParseFiles("templates/index.html"))
	err := tmpl.Execute(w, quizzes)
	if err != nil {
		http.Error(w, "Failed to render template", http.StatusInternalServerError)
	}
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}

func toJson(v interface{}) (string, error) {
	// Marshal the data into JSON format.
	jsonData, err := json.Marshal(v)
	if err != nil {
		return "", err
	}
	// Convert the JSON bytes to a string and return it.
	return string(jsonData), nil
}

func quizHandler(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/quiz/")
	quizID, err := strconv.Atoi(id)
	if err != nil {
		http.Error(w, "Invalid quiz ID", http.StatusBadRequest)
		return
	}

	var selectedQuiz Quiz
	for _, quiz := range quizzes {
		if quiz.ID == quizID {
			selectedQuiz = quiz
			break
		}
	}

	if selectedQuiz.ID == 0 {
		http.Error(w, "Quiz not found", http.StatusNotFound)
		return
	}

	tmpl := template.Must(template.New("quiz.html").Funcs(template.FuncMap{
		"toJson": toJson,
		"add":    add,
	}).ParseFiles("templates/quiz.html"))

	var buf bytes.Buffer
	//err = tmpl.Execute(&buf, selectedQuiz)
	tmpl.Execute(&buf, selectedQuiz)
	if err != nil {
		http.Error(w, "Failed to render template", http.StatusInternalServerError)
		return
	}
	buf.WriteTo(w)
}

// isPrime checks if a number is prime.
func isPrime(n int) bool {
	if n <= 1 {
		return false
	}
	if n <= 3 {
		return true
	}
	if n%2 == 0 || n%3 == 0 {
		return false
	}
	for i := 5; i*i <= n; i += 6 {
		if n%i == 0 || n%(i+2) == 0 {
			return false
		}
	}
	return true
}

// cpuIntensiveTask performs a CPU-intensive task.
func cpuIntensiveTask() {
	const max = 9000000
	for i := 2; i < max; i++ {
		isPrime(i)
	}
}

func cpuintensiveHandler(w http.ResponseWriter, r *http.Request) {
	go cpuIntensiveTask()
	fmt.Fprintf(w, "CPU-intensive task accepted")
}

func serverConfigHandler(w http.ResponseWriter, r *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
		http.Error(w, "Failed to get hostname", http.StatusInternalServerError)
		return
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		http.Error(w, "Failed to get IP address", http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Hostname: %s\n", hostname)
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				fmt.Fprintf(w, "IP Address: %s\n", ipnet.IP.String())
			}
		}
	}

	configData, err := os.ReadFile("config.yaml")
	if err != nil {
		http.Error(w, "Failed to read config file", http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "\nConfig File:\n%s\n", configData)
}

func reloadQuizzes() {
	if config.ReadFromS3 {
		loadQuizzesFromS3()
	} else {
		loadQuizzesFromFileSystem()
	}
}

func evaluateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var submittedAnswers map[string][]string

	// Parse the incoming JSON data
	err := json.NewDecoder(r.Body).Decode(&submittedAnswers)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Extract the quizId
	quizId, ok := submittedAnswers["quizId"]
	if !ok || len(quizId) == 0 {
		http.Error(w, "Quiz ID is missing", http.StatusBadRequest)
		return
	}

	// Prepare the payload for the external service
	payload := map[string]interface{}{
		"quizId":  quizId[0],
		"answers": submittedAnswers,
	}

	// Use channels to handle asynchronous processing
	resultChan := make(chan []byte)
	errorChan := make(chan error)

	go func() {
		// Make the external API call for evaluation asynchronously
		evaluationResults, err := evaluateViaExternalService(config.CheckerService, payload)
		if err != nil {
			errorChan <- err
		} else {
			resultChan <- evaluationResults
		}
	}()

	// Wait for the result or error and respond accordingly
	select {
	case evaluationResults := <-resultChan:
		w.Header().Set("Content-Type", "application/json")
		w.Write(evaluationResults)
	case err := <-errorChan:
		http.Error(w, fmt.Sprintf("Error evaluating quiz: %v", err), http.StatusInternalServerError)
	}
}

func evaluateViaExternalService(apiURL string, payload map[string]interface{}) ([]byte, error) {
	// Convert the payload to JSON
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal payload: %v", err)
	}

	// Create a new HTTP POST request with the JSON data
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	// Make the HTTP request to the external service
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call external service: %v", err)
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	// Check for non-200 HTTP status codes
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("received non-200 status code: %d", resp.StatusCode)
	}

	return body, nil
}

func main() {
	loadConfig()

	http.HandleFunc("/", handler)
	http.HandleFunc("/health", healthCheckHandler)
	http.HandleFunc("/quiz/", quizHandler)
	http.HandleFunc("/task/cpuintensive", cpuintensiveHandler)
	http.HandleFunc("/server/config", serverConfigHandler)
	http.HandleFunc("/evaluate", evaluateHandler)
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))

	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
