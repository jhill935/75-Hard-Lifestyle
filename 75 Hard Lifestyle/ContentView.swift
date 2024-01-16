//
//  ContentView.swift
//  75 Hard Lifestyle
//
//  Created by Jackson Hill on 1/15/24.
//

import SwiftUI
import MapKit
import CoreLocation
import Charts

// Define a simple data model to store the running sessions

enum TabDestination {
    case profile, lifestyle, workout, running
}

struct IdentifiableCoordinate: Identifiable, Codable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D, id: UUID = UUID()) {
        self.coordinate = coordinate
        self.id = id
    }
}
struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var isConsumed: Bool

    init(id: UUID = UUID(), name: String, isConsumed: Bool = false) {
        self.id = id
        self.name = name
        self.isConsumed = isConsumed
    }
}

struct NutritionDay: Identifiable, Codable {
    let id: UUID
    var day: String
    var meals: [Meal]

    init(id: UUID = UUID(), day: String, meals: [Meal]) {
        self.id = id
        self.day = day
        self.meals = meals
    }
}
class LifestyleViewModel: ObservableObject {
    @Published var nutritionWeek: [NutritionDay] = []

    
    init() {
        loadNutritionData()
    }
    
    private func defaultNutritionData() -> [NutritionDay]
    {
            return [
                NutritionDay(day: "Monday", meals: [
                    Meal(name: "Peanut Butter Toast and Pineapple"),
                    Meal(name: "Buffalo Chicken Wraps"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Tuesday", meals: [
                    Meal(name: "Scrambled Eggs and Fruit"),
                    Meal(name: "Chicken Salad"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Wednesday", meals: [
                    Meal(name: "Peanut Butter Toast and Pineapple"),
                    Meal(name: "Buffalo Chicken Wraps"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Thursday", meals: [
                    Meal(name: "Scrambled Eggs and Fruit"),
                    Meal(name: "Chicken Salad"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Friday", meals: [
                    Meal(name: "Peanut Butter Toast and Pineapple"),
                    Meal(name: "Buffalo Chicken Wraps"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Saturday", meals: [
                    Meal(name: "Scrambled Eggs and Fruit"),
                    Meal(name: "Chicken Salad"),
                    Meal(name: "Chicken and Rice Bowl")
                ]),
                NutritionDay(day: "Sunday", meals: [
                    Meal(name: "Peanut Butter Toast and Pineapple or Scrambled Eggs and Fruit"), // Alternating preference for Sunday
                    Meal(name: "Buffalo Chicken Wraps or Chicken Salad"), // Alternating preference for Sunday
                    Meal(name: "Chicken and Rice Bowl")
                ])
            ]
        }
    
    func toggleMealConsumed(dayIndex: Int, mealIndex: Int) {
        nutritionWeek[dayIndex].meals[mealIndex].isConsumed.toggle()
        saveNutritionData()
    }
    func resetMealsForDay(dayIndex: Int) {
        let day = nutritionWeek[dayIndex]
        nutritionWeek[dayIndex].meals = day.meals.map { Meal(name: $0.name, isConsumed: false) }
    }
    func checkIfAllMealsConsumed(dayIndex: Int) -> Bool {
        return nutritionWeek[dayIndex].meals.allSatisfy { $0.isConsumed }
    }
    func checkIfAllMealsConsumedForAllDays() -> Bool {
        return nutritionWeek.allSatisfy { day in
            day.meals.allSatisfy { $0.isConsumed }
        }
        
    }

        // Function to reset meals for all days
    func resetMealsForAllDays() {
        for i in nutritionWeek.indices {
            resetMealsForDay(dayIndex: i)
        }
        
    }
    func saveNutritionData() {
        if let encoded = try? JSONEncoder().encode(nutritionWeek) {
            UserDefaults.standard.set(encoded, forKey: "nutritionData")
        }
        
    }
    func loadNutritionData() {
        if let savedData = UserDefaults.standard.data(forKey: "nutritionData"),
           let savedNutritionWeek = try? JSONDecoder().decode([NutritionDay].self, from: savedData) {
            nutritionWeek = savedNutritionWeek
        } else{
            nutritionWeek = defaultNutritionData()
        }
        
    }
}
struct NutritionDayView: View {
    @ObservedObject var viewModel: LifestyleViewModel
    var dayIndex: Int
    @State private var isEditing: Bool = false
    @State private var listKey = UUID()

    var body: some View {
        List {
            ForEach(viewModel.nutritionWeek[dayIndex].meals.indices, id: \.self) { mealIndex in
                let meal = viewModel.nutritionWeek[dayIndex].meals[mealIndex]
                HStack {
                    if isEditing {
                        TextField("Meal Name", text: $viewModel.nutritionWeek[dayIndex].meals[mealIndex].name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(viewModel.nutritionWeek[dayIndex].meals[mealIndex].name)
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: meal.isConsumed ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(meal.isConsumed ? .green : .gray)
                        .onTapGesture {
                            viewModel.toggleMealConsumed(dayIndex: dayIndex, mealIndex: mealIndex)
                            checkAndResetAllMealsIfNeeded()
                        }
                }
                .frame(minHeight: UIScreen.main.bounds.height / CGFloat(viewModel.nutritionWeek[dayIndex].meals.count))
            }
        }
        
        .id(listKey) // Use the unique key here
        .navigationBarItems(trailing: Button(isEditing ? "Done" : "Edit") {
            isEditing.toggle()
            if !isEditing {
                viewModel.saveNutritionData() // Save changes when done editing
            }
        })
        .navigationTitle(viewModel.nutritionWeek[dayIndex].day)
        .listStyle(PlainListStyle())
    }

    private func checkAndResetAllMealsIfNeeded() {
        if viewModel.checkIfAllMealsConsumedForAllDays() {
            viewModel.resetMealsForAllDays()
        }
        
    }
    private func updateMeals() {

        let updatedMeals = viewModel.nutritionWeek[dayIndex].meals
        for meal in updatedMeals {
            print("\(meal.name)")
        }
    }
}

struct NutritionView: View {
    @ObservedObject var viewModel: LifestyleViewModel

    var body: some View {
        List {
            ForEach(viewModel.nutritionWeek.indices, id: \.self) { dayIndex in
                NavigationLink(destination: NutritionDayView(viewModel: viewModel, dayIndex: dayIndex)) {
                    HStack {
                        Text(viewModel.nutritionWeek[dayIndex].day)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .frame(minHeight: UIScreen.main.bounds.height / CGFloat(viewModel.nutritionWeek.count)) // Distribute height equally among all days

                        Spacer()

                        if viewModel.nutritionWeek[dayIndex].meals.allSatisfy({ $0.isConsumed }) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 65, height: 65)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .onDisappear {
                viewModel.saveNutritionData() // Save nutrition data when the view disappears
                
            }
        }
        .listStyle(PlainListStyle()) // Make the list go edge-to-edge
    }
}
class BudgetViewModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var grocerySpending: Double = 0
    @Published var utilitiesSpending: Double = 0
    @Published var activitiesSpending: Double = 0
    @Published var monthlySavingsGoal: Double = 0
    
    // New properties
    @Published var savingsAmount: Double = 0
    @Published var debitAccountAmount: Double = 0
    @Published var creditAmount: Double = 0

    init() {
        loadBudgetData()
    }
    
    var totalExpenses: Double {
        grocerySpending + utilitiesSpending + activitiesSpending
    }
    
    var netIncome: Double {
        monthlyIncome - totalExpenses
    }
    
    var savingsRatio: Double {
        monthlyIncome > 0 ? (savingsAmount / monthlyIncome) * 100 : 0
    }

    var projectedYearlySavings: Double {
        savingsAmount * 12
    }

    
    func saveBudgetData() {
        UserDefaults.standard.set(monthlyIncome, forKey: "monthlyIncome")
        UserDefaults.standard.set(grocerySpending, forKey: "grocerySpending")
        UserDefaults.standard.set(utilitiesSpending, forKey: "utilitiesSpending")
        UserDefaults.standard.set(activitiesSpending, forKey: "activitiesSpending")
        UserDefaults.standard.set(monthlySavingsGoal, forKey: "monthlySavingsGoal")
        
        // New properties
        UserDefaults.standard.set(savingsAmount, forKey: "savingsAmount")
        UserDefaults.standard.set(debitAccountAmount, forKey: "debitAccountAmount")
        UserDefaults.standard.set(creditAmount, forKey: "creditAmount")
    }

    func loadBudgetData() {
        monthlyIncome = UserDefaults.standard.double(forKey: "monthlyIncome")
        grocerySpending = UserDefaults.standard.double(forKey: "grocerySpending")
        utilitiesSpending = UserDefaults.standard.double(forKey: "utilitiesSpending")
        activitiesSpending = UserDefaults.standard.double(forKey: "activitiesSpending")
        monthlySavingsGoal = UserDefaults.standard.double(forKey: "monthlySavingsGoal")
        
        // New properties
        savingsAmount = UserDefaults.standard.double(forKey: "savingsAmount")
        debitAccountAmount = UserDefaults.standard.double(forKey: "debitAccountAmount")
        creditAmount = UserDefaults.standard.double(forKey: "creditAmount")
    }
}
struct ExpenseCategory: Identifiable {
    let id = UUID()
    var category: String
    var amount: Double
}

extension BudgetViewModel {
    var expenseCategories: [ExpenseCategory] {
        [
            ExpenseCategory(category: "Groceries", amount: grocerySpending),
            ExpenseCategory(category: "Utilities", amount: utilitiesSpending),
            ExpenseCategory(category: "Activities", amount: activitiesSpending)
        ]
    }
    var monthsToSurvive: String {
        if monthlyIncome > 0 {
            return "N/A"
        } else {
            let totalFunds = savingsAmount + debitAccountAmount - creditAmount
            if totalExpenses > 0 {
                let months = totalFunds / totalExpenses
                return months > 0 ? String(format: "%.1f months", months) : "0 months (Insufficient funds)"
            } else {
                return "Indefinite (No expenses)"
            }
        }
        
    }
}
struct BudgetQuestionnaireView: View {
    @ObservedObject var budgetViewModel: BudgetViewModel
    @State private var showBudgetCalculations = false

    var body: some View {
        VStack {
            Text("Please enter your details")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .padding(.top, 20) // Adjust top padding as needed
            
            ScrollView{
                VStack(spacing: 20) { // Adds spacing between each question
                    BudgetQuestionItem(label: "Monthly Amount Made:", value: $budgetViewModel.monthlyIncome)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    BudgetQuestionItem(label: "How much is in your savings currently:", value: $budgetViewModel.savingsAmount)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    
                    BudgetQuestionItem(label: "How much is in your debit account:", value: $budgetViewModel.debitAccountAmount)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    
                    BudgetQuestionItem(label: "How much credit do you have built up:", value: $budgetViewModel.creditAmount)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    
                    BudgetQuestionItem(label: "Grocery Spending:", value: $budgetViewModel.grocerySpending)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    BudgetQuestionItem(label: "Utilities Spending:", value: $budgetViewModel.utilitiesSpending)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    BudgetQuestionItem(label: "Activities and Fun:", value: $budgetViewModel.activitiesSpending)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    BudgetQuestionItem(label: "Monthly Savings Goal:", value: $budgetViewModel.monthlySavingsGoal)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                }
            }
            .padding()
            
            Button("Save") {
                budgetViewModel.saveBudgetData()
                showBudgetCalculations = true // Trigger the sheet presentation
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            
        }
        
        .sheet(isPresented: $showBudgetCalculations) { // Present the BudgetCalculationsView when showBudgetCalculations is true
            BudgetCalculationsView(budgetViewModel: budgetViewModel)
        }
            
        .onAppear {
            budgetViewModel.loadBudgetData()
            
        }
        .onDisappear {
            budgetViewModel.saveBudgetData() // Save budget data when the view disappears
        }
    }
}

struct BudgetQuestionItem: View {
    var label: String
    @Binding var value: Double
    let formatter: NumberFormatter

    init(label: String, value: Binding<Double>) {
        self.label = label
        self._value = value
        self.formatter = NumberFormatter()
        self.formatter.numberStyle = .currency
        self.formatter.locale = Locale.current
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)

            TextField("Enter amount", value: $value, formatter: formatter)
                .textFieldStyle(.roundedBorder)
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .keyboardType(.decimalPad)
        }
    }
}

struct BudgetCalculationsView: View {
    @ObservedObject var budgetViewModel: BudgetViewModel

    var body: some View {
        List {
            Section(header: Text("Your Budget Summary").font(.system(size: 20, weight: .heavy, design: .rounded))) {

                HStack {
                    Text("Monthly Savings Goal:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text("\(budgetViewModel.monthlySavingsGoal, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }

                HStack {
                    Text("Total Expenses:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text("\(budgetViewModel.totalExpenses, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
                HStack {
                    Text("Savings Ratio (%):")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text("\(budgetViewModel.savingsRatio, specifier: "%.2f")%")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    
                }

                HStack {
                    Text("Projected Yearly Savings:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text("\(budgetViewModel.projectedYearlySavings, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    
                }
                HStack {
                    Text("Months to Survive with Current Funds:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text(budgetViewModel.monthsToSurvive)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(budgetViewModel.monthlyIncome > 0 ? .gray : (budgetViewModel.totalExpenses > 0 ? .green : .red))
                    
                }

                HStack {
                    Text("Net Income:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Spacer()
                    Text("\(budgetViewModel.netIncome, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(budgetViewModel.netIncome >= 0 ? .green : .red)
                }
                HStack{
                    if #available(iOS 16.0, macOS 13.0, *) {
                        Chart {
                            ForEach(budgetViewModel.expenseCategories) { category in
                                BarMark(
                                    x: .value("Category", category.category),
                                    y: .value("Amount", category.amount)
                                )
                            }
                            
                        }
                        .frame(height: 300)
                    } else {
                        // Fallback for earlier versions
                        Text("Charts are not available in this iOS version.")
                        
                    }
                }
            }
        }
    }
}
struct LifestyleView: View {
    @ObservedObject var lifestyleViewModel: LifestyleViewModel
    @StateObject var budgetViewModel = BudgetViewModel()

    var body: some View {
        VStack {
            NavigationLink(destination: NutritionView(viewModel: lifestyleViewModel)) {
                VStack {
                    Image(systemName: "leaf.circle") // Replace with your own image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Text("Nutrition")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                }
                .frame(minWidth: 0, maxWidth: 325, minHeight: 0, maxHeight: 325)
                .background(Color.black.opacity(0))
                .cornerRadius(20)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 7))
            }
            .buttonStyle(PlainButtonStyle())

            .padding()
            
            NavigationLink(destination: BudgetQuestionnaireView(budgetViewModel: budgetViewModel)) {
                VStack {
                    Image(systemName: "dollarsign.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Text("Budget")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                }
                .frame(minWidth: 0, maxWidth: 325, minHeight: 0, maxHeight: 325)
                .background(Color.black.opacity(0))
                .cornerRadius(20)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.blue.opacity(0.8), lineWidth: 7))
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
    }
}
struct Workout: Codable {
    let id: UUID
    var name: String
    var sets: String
    var isComplete: Bool

    init(id: UUID = UUID(), name: String, sets: String, isComplete: Bool = false) {
        self.id = id
        self.name = name
        self.sets = sets
        self.isComplete = isComplete
    }
}

struct Day: Identifiable, Codable {
    let id: UUID
    var name: String
    var workouts: [Workout]

    init(id: UUID = UUID(), name: String, workouts: [Workout]) {
        self.id = id
        self.name = name
        self.workouts = workouts
    }
    
    // Computed property to check if all workouts in the day are complete
    var isComplete: Bool {
        return workouts.allSatisfy { $0.isComplete }
    }
    
    // Method to reset all workouts in the day
    mutating func resetWorkouts() {
        workouts = workouts.map { Workout(name: $0.name, sets: $0.sets, isComplete: false) }
    }
}
class Week: ObservableObject {
    @Published var days: [Day]

    init() {
        self.days = [
            Day(name: "Monday", workouts: [
                Workout(name: "Dumbbell Bench Press", sets: "4 sets of 10-12 reps"),
                Workout(name: "One-Arm Dumbbell Row", sets: "4 sets of 10-12 reps each side"),
                Workout(name: "Russian Twists", sets: "3 sets of 15 reps each side"),
                Workout(name: "Cable Flyes", sets: "3 sets of 12 reps"),
                Workout(name: "Wide-Grip Lat Pulldown", sets: "3 sets of 10-12 reps"),
                Workout(name: "Hanging Leg Raises", sets: "3 sets of 10-12 reps")
            ]),
            Day(name: "Tuesday", workouts: [
                Workout(name: "Goblet Squats", sets: "4 sets of 10-12 reps"),
                Workout(name: "Stability Ball Hamstring Curls", sets: "4 sets of 10-12 reps"),
                Workout(name: "Cable Kickbacks", sets: "4 sets of 12 reps per leg"),
                Workout(name: "Standing Calf Raises", sets: "4 sets of 15 reps"),
                Workout(name: "Walking Lunges", sets: "3 sets of 10 reps per leg"),
                Workout(name: "Box Jumps", sets: "3 sets of 10 reps")
            ]),
            Day(name: "Wednesday", workouts: [
                Workout(name: "Seated Dumbbell Press", sets: "4 sets of 10-12 reps"),
                Workout(name: "EZ Bar Curl", sets: "4 sets of 10-12 reps"),
                Workout(name: "Tricep Rope Pushdown", sets: "4 sets of 10-12 reps"),
                Workout(name: "Front Raises", sets: "3 sets of 12 reps"),
                Workout(name: "Preacher Curls", sets: "3 sets of 10 reps"),
                Workout(name: "Bench Dips", sets: "3 sets of 12-15 reps")
            ]),
            Day(name: "Thursday", workouts: [
                Workout(name: "Leg Press", sets: "4 sets of 10-12 reps"),
                Workout(name: "Deadlifts", sets: "4 sets of 10 reps"),
                Workout(name: "Glute Bridges", sets: "4 sets of 12 reps"),
                Workout(name: "Seated Calf Raises", sets: "4 sets of 15 reps"),
                Workout(name: "Sumo Squats", sets: "3 sets of 10-12 reps"),
                Workout(name: "Single Leg Deadlifts", sets: "3 sets of 10 reps per leg")
            ]),
            Day(name: "Friday", workouts: [
                Workout(name: "Incline Dumbbell Press", sets: "4 sets of 10-12 reps"),
                Workout(name: "T-Bar Row", sets: "4 sets of 10-12 reps"),
                Workout(name: "Decline Bench Sit-Ups", sets: "3 sets of 15 reps"),
                Workout(name: "Pec Deck Machine", sets: "3 sets of 12 reps"),
                Workout(name: "Pull-Ups (assisted if necessary)", sets: "3 sets of 8-10 reps"),
                Workout(name: "Ab Wheel Rollouts", sets: "3 sets of 10 reps")
            ]),
            Day(name: "Saturday", workouts: [
                Workout(name: "Front Squats", sets: "4 sets of 10 reps"),
                Workout(name: "Lying Leg Curls", sets: "4 sets of 12 reps"),
                Workout(name: "Weighted Step-Ups", sets: "4 sets of 10 reps per leg"),
                Workout(name: "Calf Press on the Leg Machine", sets: "4 sets of 15 reps"),
                Workout(name: "Bulgarian Split Squats", sets: "3 sets of 10 reps per leg"),
                Workout(name: "Kettlebell Swings", sets: "3 sets of 15 reps")
            ]),
            Day(name: "Sunday", workouts: [
                Workout(name: "Arnold Press", sets: "4 sets of 10-12 reps"),
                Workout(name: "Incline Dumbbell Curl", sets: "4 sets of 10 reps per arm"),
                Workout(name: "Skull Crushers", sets: "4 sets of 10-12 reps"),
                Workout(name: "Bent-Over Reverse Flyes", sets: "3 sets of 12 reps"),
                Workout(name: "Concentration Curls", sets: "3 sets of 10 reps per arm"),
                Workout(name: "Overhead Cable Extension", sets: "3 sets of 12 reps")
            ])
        ]
    }
    func toggleWorkoutComplete(dayIndex: Int, workoutIndex: Int) {
        let isComplete = days[dayIndex].workouts[workoutIndex].isComplete
        days[dayIndex].workouts[workoutIndex].isComplete = !isComplete
        // Manually notify observers that there has been a change.
        objectWillChange.send()
        // Then save your data as needed.
        
    }
    
    func resetWeek() {
        for i in days.indices {
            days[i].resetWorkouts()
        }
        
    }
    
}
class WorkoutViewModel: ObservableObject {
    @Published var week = Week()

    init() {
        loadWeekData()
    }
    // Function to reset the workouts for the entire week
    func resetWeek() {
        week.resetWeek()
        saveWeekData()
    }
    
    // Function to check if all days in the week are complete
    func checkIfAllDaysComplete() -> Bool {
        return week.days.allSatisfy { $0.isComplete }
    }

    // Call this method to reset the week when all days are complete
    func endOfWeekReset() {
        if checkIfAllDaysComplete() {
            resetWeek()
        }
    }

    func toggleWorkoutComplete(dayIndex: Int, workoutIndex: Int) {
        // Toggle the isComplete state
        week.days[dayIndex].workouts[workoutIndex].isComplete.toggle()
        
        // Save the data
        saveWeekData()
        
        // Important: This will cause the view to update
        objectWillChange.send()
        endOfWeekReset()
    }
        
    func saveWeekData() {
        if let encoded = try? JSONEncoder().encode(week.days) {
            UserDefaults.standard.set(encoded, forKey: "weekData")
        }
        
    }
        
    func loadWeekData() {
        if let weekData = UserDefaults.standard.data(forKey: "weekData"),
           let savedDays = try? JSONDecoder().decode([Day].self, from: weekData) {
            week.days = savedDays
        }
        
    }
}
struct WeekView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var allWorkoutsCompletedPreviously = false

    var body: some View {
        List {
            ForEach(viewModel.week.days.indices, id: \.self) { dayIndex in
                NavigationLink(destination: WorkoutChecklistView(viewModel: viewModel, dayIndex: dayIndex)) {
                    HStack {
                        Text(viewModel.week.days[dayIndex].name)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .frame(minHeight: UIScreen.main.bounds.height / CGFloat(viewModel.week.days.count)) // This will distribute the height equally among all days.
                        Spacer()
                        if viewModel.week.days[dayIndex].isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable() // Make the image resizable
                                .scaledToFit() // Ensure it scales to fit while keeping aspect ratio
                                .frame(width: 65, height: 65) // Set the frame size to be larger
                                .foregroundColor(.green)
                            
                            
                        }
                    }
                }
            }
            
        }
        .listStyle(PlainListStyle()) // This will make the list go edge-to-edge.
        .onAppear {
            viewModel.loadWeekData()
        }
        .onDisappear {
            // If all workouts were completed when this view appeared,
            // and the user is now navigating away, reset the week.
            if allWorkoutsCompletedPreviously {
                viewModel.resetWeek()
            }
        }
    }
}
struct WorkoutChecklistView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    var dayIndex: Int
    @State private var isEditing: Bool = false // Add this line to toggle editing

    var body: some View {
        List {
            ForEach(viewModel.week.days[dayIndex].workouts.indices, id: \.self) { workoutIndex in
                let workout = viewModel.week.days[dayIndex].workouts[workoutIndex]
                HStack {
                    if isEditing {
                        TextField("Workout Name", text: $viewModel.week.days[dayIndex].workouts[workoutIndex].name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                        TextField("Sets", text: $viewModel.week.days[dayIndex].workouts[workoutIndex].sets)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                    } else {
                        Text(workout.name)
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                        Spacer()
                        Text(workout.sets)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: workout.isComplete ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(workout.isComplete ? .green : .gray)
                        .onTapGesture {
                            viewModel.toggleWorkoutComplete(dayIndex: dayIndex, workoutIndex: workoutIndex)
                        }
                }
                .frame(minHeight: UIScreen.main.bounds.height / CGFloat(viewModel.week.days[dayIndex].workouts.count))
            }
            .onDelete { indices in
                viewModel.week.days[dayIndex].workouts.remove(atOffsets: indices)
            }
        }
        .navigationTitle(viewModel.week.days[dayIndex].name)
        .listStyle(PlainListStyle())
        .navigationBarItems(trailing: Button(isEditing ? "Done" : "Edit") {
            isEditing.toggle()
            if !isEditing {
                viewModel.saveWeekData() // Call this method to save changes
            }
        })
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }
}
struct WorkoutView: View {
    @StateObject var viewModel = WorkoutViewModel()
    
    var body: some View {
        WeekView(viewModel: viewModel)
            .navigationTitle("")
            .onAppear {
                viewModel.loadWeekData()
                
            }
            .onDisappear {
                viewModel.saveWeekData() // Save workout data when the view disappears
                
            }
    }
    
}
struct UserProfile: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var gender: String = ""
    var profilePicture: Data? // Storing image as Data
    var goals: String = ""
    var progressPictures: [Data] = [] // Changed to an array of Data
}
struct RunningSession: Identifiable, Codable {
    let id: UUID
    let day: Int
    let time: TimeInterval
    let distance: Double
    let route: [CLLocationCoordinate2D]
    var completed: Bool

    init(day: Int, time: TimeInterval, distance: Double, route: [CLLocationCoordinate2D], completed: Bool, id: UUID = UUID()) {
        self.day = day
        self.time = time
        self.distance = distance
        self.route = route
        self.completed = completed
        self.id = id
    }
}
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                self.parent.onImagePicked(image) // Call the completion handler with the selected image
            }
            picker.dismiss(animated: true)
            
        }
    }
}
class ProfileViewModel: ObservableObject {
    @Published var userProfile = UserProfile()
    @Published var profileImage: UIImage?
    @Published var progressImages: [UIImage] = [] // Changed to an array of UIImages
    @Published var isEditing = false
    
    func saveProfile() {
        // Convert UIImage to Data for profile picture
        userProfile.profilePicture = profileImage?.jpegData(compressionQuality: 1.0)
        // Convert each UIImage in the progress images array to Data
        userProfile.progressPictures = progressImages.map { $0.jpegData(compressionQuality: 1.0) ?? Data() }
        
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }

    func loadProfile() {
        if let savedProfile = UserDefaults.standard.object(forKey: "userProfile") as? Data {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
                self.userProfile = decodedProfile
                // Convert Data back to UIImage for profile picture
                if let profilePicData = userProfile.profilePicture {
                    self.profileImage = UIImage(data: profilePicData)
                }
                // Convert each Data back to UIImage for progress pictures
                self.progressImages = userProfile.progressPictures.compactMap { UIImage(data: $0) }
            }
        }
    }
    
    func addProgressImage(image: UIImage) {
        progressImages.append(image)
    }
    func removeProgressImage(at index: Int) {
        progressImages.remove(at: index)
        
    }
    func setProfileImage(image: UIImage) {
        profileImage = image
    }
}
enum ImageType {
    case profile
    case progress
}
extension View {
    func centerHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}
struct ProfileView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
        @State private var showingImagePicker = false
        @State private var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
        @State private var activeImageType: ImageType = .profile // New state variable
    

    var body: some View {
        VStack {
            if profileViewModel.isEditing {
                // If editing, show the editable content
                editableContent
            } else {
                // If not editing, show the readonly profile content
                readonlyContent
            }
        }
        .navigationBarItems(trailing: Button(profileViewModel.isEditing ? "Done" : "Edit") {
            // Toggle the editing state
            profileViewModel.isEditing.toggle()
            // If we just finished editing, save the profile
            if !profileViewModel.isEditing {
                profileViewModel.saveProfile()
            }
        })
        .onAppear {
            profileViewModel.loadProfile()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: Binding<UIImage?>(get: {
                nil // This is a dummy get for the binding since we handle the image directly in the `onImagePicked`
            }, set: { _ in
                // We do not set the image here, as we will handle it in the `onImagePicked`
            }), sourceType: imagePickerSourceType, onImagePicked: { image in
                // Handle the picked image
                if activeImageType == .profile {
                    profileViewModel.setProfileImage(image: image)
                } else {
                    profileViewModel.addProgressImage(image: image)
                }
            })
        }
    }
    var editableContent: some View {
        List {
            Section(header: Text("Profile Information")) {
                // This will display the profile picture in a circle above the text fields
                if let profileImage = profileViewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100) // Adjust the size as needed
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .padding(.bottom) // Add some padding if needed
                    
                }
                Button("Select Profile Picture") {
                    activeImageType = .profile
                    showingImagePicker = true
                    
                }
                TextField("First Name", text: $profileViewModel.userProfile.firstName)
                TextField("Last Name", text: $profileViewModel.userProfile.lastName)
                TextField("Gender", text: $profileViewModel.userProfile.gender)
                TextField("Goals", text: $profileViewModel.userProfile.goals)
                
            }
            Section(header: Text("Progress Pictures")) {
                ForEach(Array(profileViewModel.progressImages.enumerated()), id: \.element) { index, img in
                    HStack {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                        
                        Spacer()
                        
                        if profileViewModel.isEditing {
                            Button(action: {
                                profileViewModel.removeProgressImage(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if profileViewModel.isEditing {
                    Button("Add Progress Picture") {
                        activeImageType = .progress
                        showingImagePicker = true
                    }
                }
                
            }
            
            Button("Save Profile") {
                profileViewModel.saveProfile()
                profileViewModel.isEditing = false // Turn off editing mode after saving
            }
        }
    }

        // Define the readonly content in a computed property or a separate view
    var readonlyContent: some View {
        List {
            // Display profile image in a circle at the top, centered
            if let profileImage = profileViewModel.profileImage {
                Section {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100) // Adjust the size as needed
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .padding(.bottom) // Add some padding if needed
                }
                .listRowInsets(EdgeInsets())
                .textCase(nil)
                .centerHorizontally() // Extension to center in List
                Text("\(profileViewModel.userProfile.firstName) \(profileViewModel.userProfile.lastName)")
                Text("\(profileViewModel.userProfile.gender)")
                Text("\(profileViewModel.userProfile.goals)")
            }
            Section(header: Text("Progress Pictures")) {
                ForEach(profileViewModel.progressImages, id: \.self) { img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
    }
    
    
    private func deleteProgressImage(at offsets: IndexSet) {
        profileViewModel.progressImages.remove(atOffsets: offsets)
    }
}

class RunningViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var runningSessions: [RunningSession] = []
    @Published var currentRoute: [IdentifiableCoordinate] = []
    @Published var distance: Double = 0
    @Published var mapCameraPosition: MapCameraPosition
    @Published var userLocation: CLLocationCoordinate2D?
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    var isRunningSessionActive = false
    
    override init() {
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0149, longitude: -105.2705),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapCameraPosition = MapCameraPosition.region(initialRegion)
        super.init()
        // Any additional setup can be done here, after super.init()
        loadRunningSessions()
    }

    private func saveRunningSessions() {
        if let encoded = try? JSONEncoder().encode(runningSessions) {
            UserDefaults.standard.set(encoded, forKey: "runningSessions")
        }
        
    }
    public func saveData() {
            saveRunningSessions()
        }
    private func loadRunningSessions() {
        if let savedSessions = UserDefaults.standard.object(forKey: "runningSessions") as? Data {
            if let decodedSessions = try? JSONDecoder().decode([RunningSession].self, from: savedSessions) {
                self.runningSessions = decodedSessions
            }
        }
        
    }
    func addSession(time: TimeInterval, distance: Double, route: [CLLocationCoordinate2D]) {
        let newSession = RunningSession(day: runningSessions.count + 1, time: time, distance: distance, route: route, completed: true)
        runningSessions.append(newSession)
        saveRunningSessions()
    }

    func startLocationUpdates() {
        locationManager.requestAlwaysAuthorization() // Change to always authorization
        locationManager.allowsBackgroundLocationUpdates = true // Enable background updates
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        distance = 0
        currentRoute.removeAll()
    }
    
    func updateMapCameraPosition() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0149, longitude: -105.2705), // Use your desired coordinates
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapCameraPosition = MapCameraPosition.region(region) // Update this line to set the mapCameraPosition
        
    }
}

extension RunningViewModel{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Check if the user is currently in a running session
        if isRunningSessionActive {
            if let lastLocation = self.lastLocation {
                let distanceInMeters = location.distance(from: lastLocation)
                let distanceInMiles = distanceInMeters / 1609.34 // convert to miles
                DispatchQueue.main.async {
                    self.distance += distanceInMiles // Update your distance state here
                }
            }
            self.lastLocation = location
        }

        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.currentRoute.append(IdentifiableCoordinate(coordinate: location.coordinate))
            
            // Update the map camera position to follow the user
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            self.mapCameraPosition = MapCameraPosition.region(region)
            
        }
    }
}

struct RunningView: View {
    @ObservedObject var viewModel: RunningViewModel
    @State private var isRunningSessionActive = false
    
    var body: some View {
        VStack {
            Text("Running Stats")
                .font(.system(size: 35, weight: .heavy, design: .rounded))
                .padding()
            
            List {
                ForEach(viewModel.runningSessions) { session in
                    HStack {
                        Image(systemName: session.completed ? "checkmark.square" : "square")
                        Text("Day \(session.day) - Time: \(formatTime(session.time))   Distance: \(session.distance, specifier: "%.2f") miles")
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2))
                }
            }
            Button(action: {
                isRunningSessionActive = true
            }) {
                Text("START RUN")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding()
        }
        .navigationTitle("")
        .navigationDestination(isPresented: $isRunningSessionActive) {
            RunningSessionView(viewModel: viewModel, distance: $viewModel.distance)
        }
    }
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) / 60 % 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}
struct PrimaryButtonStyle: ButtonStyle {
    var isRunning: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(isRunning ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct RunningSessionView: View {
    @ObservedObject var viewModel: RunningViewModel
        @State private var timeElapsed: TimeInterval = 0
        @Binding var distance: Double
        @State private var timer: Timer?
        @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        
    var body: some View {
        VStack
        {
            
            Text(formatTime(timeElapsed))
                .font(.largeTitle)
                .padding()
                .background(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 4))
                .padding(.top, 10)
            
            Text(" \(viewModel.distance, specifier: "%.2f") miles")
                .padding()
                .background(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 3))
                
            Map(position: $viewModel.mapCameraPosition) {
                UserAnnotation()
            }
            .frame(height: 440)
            .edgesIgnoringSafeArea(.all)
            .background(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.blue, lineWidth: 5))
            .padding()
            Spacer()
            if timer == nil {
                Button("Start Run") {
                    startTimer()
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("End Run") {
                    stopTimer()
                }
                .buttonStyle(PrimaryButtonStyle(isRunning: true))
            }
        }
        .onAppear {
            viewModel.startLocationUpdates()
            viewModel.updateMapCameraPosition() // Call this to set the initial camera position
        }
        .onDisappear {
            viewModel.stopLocationUpdates()
        }
        .padding()
        
    }
    
    func startTimer() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        viewModel.isRunningSessionActive = true
        timeElapsed = 0 // Reset the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timeElapsed += 1
        }
    }
    
    func stopTimer() {
        if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        viewModel.isRunningSessionActive = false
        timer?.invalidate()
        timer = nil
        let routeCoordinates = viewModel.currentRoute.map { $0.coordinate }
        viewModel.addSession(time: timeElapsed, distance: distance, route: routeCoordinates)
        // Reset distance and route
        viewModel.stopLocationUpdates()
    }
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) / 60 % 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

// ViewModel remains the same as before.
// Define the view model to manage the app's state
class AppViewModel: ObservableObject {
    @Published var username: String = ""
        @Published var showHomePage: Bool

    init() {
        let hasLaunchedOnce = UserDefaults.standard.bool(forKey: "HasLaunchedOnce")
        
        // If it's the first launch, show the welcome page, else show the home page
        showHomePage = hasLaunchedOnce
        
        if hasLaunchedOnce {
            // If not the first launch, set the username to the saved value
            username = UserDefaults.standard.string(forKey: "Username") ?? ""
        }
        
    }
        
    func startButtonTapped() {
        UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
        UserDefaults.standard.set(username, forKey: "Username")
        
        if UserDefaults.standard.object(forKey: "LaunchDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "LaunchDate")
        }
        
        showHomePage = true
        
    }
    
    func dayCounter() -> Int {
           // Get the number of days since the app was first launched
           guard let launchDate = UserDefaults.standard.object(forKey: "LaunchDate") as? Date else {
               return 1 // Start counting from day 1 instead of day 0
           }
           let days = Calendar.current.dateComponents([.day], from: launchDate, to: Date()).day ?? 0
           return days + 1 // Add 1 to include the current day in the count
       }
}
struct SplashScreenView: View {
        
    var body: some View {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "dollarsign.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    
                    Image(systemName: "dumbbell")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "figure.run")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                }
                Text("75 Hard")
                    .font(.system(size: 75, weight: .heavy, design: .rounded))
                Text("Welcome to a New Lifestyle")
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
        }
}
struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var runningViewModel = RunningViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var lifestyleViewModel = LifestyleViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @State private var showSplashScreen = false
    
    var body: some View {
        NavigationView {
            if viewModel.showHomePage {
                if showSplashScreen {
                    SplashScreenView()
                        .onAppear {
                            // Hide the splash screen after 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSplashScreen = false
                            }
                        }
                } else {
                    HomePageView(viewModel: viewModel, runningViewModel: runningViewModel)
                    // Rest of your views...
                }
            } else {
                WelcomeView(viewModel: viewModel)
            }
            
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "HasLaunchedOnce") {
                // First launch, show welcome view
                viewModel.showHomePage = false
            } else {
                // Not the first launch, show splash screen
                viewModel.showHomePage = true
                showSplashScreen = true
            }
            
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            lifestyleViewModel.saveNutritionData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            budgetViewModel.saveBudgetData()
            // Call save methods for any other data that needs to be persisted
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            workoutViewModel.saveWeekData() // Save when the app is going into the background
            
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            runningViewModel.saveData()
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Use this if you want a traditional stack navigation
    }
}

struct WelcomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "dollarsign.circle")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                
                Image(systemName: "dumbbell")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Image(systemName: "figure.run")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
            }
            Text("75 Hard")
                .font(.system(size: 75, weight: .heavy, design: .rounded))
            Text("Welcome to a New Lifestyle")
                .font(.title)
                .fontWeight(.semibold)
            Spacer()
            TextField("First Name", text: $viewModel.username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            Button(action: {
                viewModel.startButtonTapped()
            }) {
                Text("START")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct HomePageView: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var runningViewModel: RunningViewModel // ViewModel for running sessions
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var lifestyleViewModel = LifestyleViewModel()
    @ObservedObject var profileViewModel = ProfileViewModel()
    @State private var navigationPath = NavigationPath() // This will keep track of the navigation stack
    
        
    var body: some View
    {
        NavigationStack(path: $navigationPath) {
            VStack {
                HStack {
                    Text("Hello \(viewModel.username)")
                        .font(.headline)
                        .padding(.leading, 20)
                        .padding(.top, 0) // Add padding to top if needed
                    Spacer()
                    NavigationLink("Profile", value: TabDestination.profile)
                        .buttonStyle(.automatic)
                        .padding(.trailing, 20)
                }
                
                Text("Here is your Progress and Lifestyle")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .padding(.top, 30)
                
                Text("During 75 Hard!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .padding(.leading, 20)
                
                Spacer() // Centers the day counter circle
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 30)
                        .opacity(0.3)
                        .foregroundColor(Color.blue)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.dayCounter()) / 75)
                        .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.blue)
                        .rotationEffect(Angle(degrees: 270))
                        .animation(.linear, value: viewModel.dayCounter())
                    
                    VStack {
                        Text("DAY")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                        Text("\(viewModel.dayCounter())")
                            .font(.system(size: 90, weight: .heavy, design: .rounded))
                        
                    }
                }
                .frame(width: 300, height: 300)
                .padding(.bottom, 50) // Adjust padding as needed
                
                Spacer() // Pushes icons towards the bottom
                
                HStack
                {
                    Spacer() // For even spacing
                    VStack{
                        Image(systemName: "dollarsign.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        
                        NavigationLink("Lifestyle", value: TabDestination.lifestyle)
                            .buttonStyle(.automatic)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                        
                    }
                    Spacer() // For even spacing
                    VStack{
                        Image(systemName: "dumbbell")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        NavigationLink("Workout", value: TabDestination.workout)
                            .buttonStyle(.automatic)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                        
                        
                    }
                    Spacer() // For even spacing
                    // Running button
                    VStack {
                        Image(systemName: "figure.run")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .padding(.trailing, 40)
                        NavigationLink("Running", value: TabDestination.running)
                            .buttonStyle(.automatic)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .padding(.trailing, 40)
                        
                    }
                }
                // Navigation Destinations
                .navigationDestination(for: TabDestination.self)
                { destination in
                    switch destination
                    {
                    case .profile:
                        ProfileView(profileViewModel: profileViewModel)
                    case .lifestyle:
                        LifestyleView(lifestyleViewModel: lifestyleViewModel)
                    case .workout:
                        WorkoutView()
                    case .running:
                        RunningView(viewModel: runningViewModel)
                    }
                    
                }
            }
        }
        .padding(.bottom, 25) // Pushes icons towards the edge of the screen
    }
}

// Preview remains the same as before.

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
