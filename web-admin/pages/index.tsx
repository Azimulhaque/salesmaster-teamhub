import { Box, Heading, SimpleGrid, Text, Flex } from '@chakra-ui/react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Button from '../components/Button';
import { useToast } from '../components/Toast';

const HomePage: React.FC = () => {
  const { showToast } = useToast();

  const handleShowToast = () => {
    showToast({
      title: 'Welcome!',
      description: 'You are viewing the SalesMaster Admin Dashboard.',
      status: 'success',
    });
  };

  return (
    <Layout>
      <Box>
        <Flex justifyContent="space-between" alignItems="center" mb={6}>
          <Heading as="h1" size="xl" color="brand.blue-700">
            Welcome to SalesMaster Admin!
          </Heading>
          <Button onClick={handleShowToast}>Show Welcome Toast</Button>
        </Flex>

        <Text fontSize="lg" mb={8} color="neutrals.gray-600">
          Overview of your sales and team performance.
        </Text>

        <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} spacing={6}>
          <Card>
            <Heading as="h2" size="md" mb={2} color="brand.blue-600">
              Total Sales
            </Heading>
            <Text fontSize="3xl" fontWeight="bold" color="highlight.gold-600">
              $1,234,567
            </Text>
            <Text fontSize="sm" color="neutrals.gray-500">
              +12% from last month
            </Text>
          </Card>

          <Card>
            <Heading as="h2" size="md" mb={2} color="brand.blue-600">
              Active Users
            </Heading>
            <Text fontSize="3xl" fontWeight="bold" color="highlight.gold-600">
              1,500
            </Text>
            <Text fontSize="sm" color="neutrals.gray-500">
              +5% from last week
            </Text>
          </Card>

          <Card>
            <Heading as="h2" size="md" mb={2} color="brand.blue-600">
              New Leads
            </Heading>
            <Text fontSize="3xl" fontWeight="bold" color="highlight.gold-600">
              250
            </Text>
            <Text fontSize="sm" color="neutrals.gray-500">
              +20% from yesterday
            </Text>
          </Card>

          <Card>
            <Heading as="h2" size="md" mb={2} color="brand.blue-600">
              Team Engagement
            </Heading>
            <Text fontSize="3xl" fontWeight="bold" color="highlight.gold-600">
              85%
            </Text>
            <Text fontSize="sm" color="neutrals.gray-500">
              Satisfactory
            </Text>
          </Card>
        </SimpleGrid>
      </Box>
    </Layout>
  );
};

export default HomePage;
