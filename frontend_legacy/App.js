import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import LoginScreen from './screens/LoginScreen';
import RegisterScreen from './screens/RegisterScreen';
import ActivityListScreen from './screens/ActivityListScreen';
import CreateActivityScreen from './screens/CreateActivityScreen';
import ProfileScreen from './screens/ProfileScreen';
import ActivityManagementScreen from './screens/ActivityManagementScreen';

const Stack = createStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
        <Stack.Screen name="Register" component={RegisterScreen} options={{ headerTitle: '注册' }} />
        <Stack.Screen name="ActivityList" component={ActivityListScreen} options={{ headerTitle: '活动列表' }} />
        <Stack.Screen name="CreateActivity" component={CreateActivityScreen} options={{ headerTitle: '创建活动' }} />
        <Stack.Screen name="Profile" component={ProfileScreen} options={{ headerTitle: '我的' }} />
        <Stack.Screen name="ActivityManagement" component={ActivityManagementScreen} options={{ headerTitle: '活动管理' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}