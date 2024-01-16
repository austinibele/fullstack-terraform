# Use the official Node.js 16 image as a parent image
FROM node:16-alpine

# Set the working directory
WORKDIR /usr/src/app

# Add a simple NextJS app
RUN npx create-next-app --typescript .
RUN echo "import fetch from 'node-fetch';" > pages/index.tsx
RUN echo "export default function Home({ message }) {" >> pages/index.tsx
RUN echo "  return <div>Hello World! Message from backend: {message}</div>;" >> pages/index.tsx
RUN echo "}" >> pages/index.tsx
RUN echo "export async function getServerSideProps() {" >> pages/index.tsx
RUN echo "  const res = await fetch('http://backend:5252/message');" >> pages/index.tsx
RUN echo "  const data = await res.json();" >> pages/index.tsx
RUN echo "  return { props: { message: data.message } };" >> pages/index.tsx
RUN echo "}" >> pages/index.tsx

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the app
CMD [ "npm", "run", "dev" ]